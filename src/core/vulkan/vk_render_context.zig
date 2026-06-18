const std = @import("std");
const core = @import("../core.zig");
const vk = core.vk;
const glfw = core.glfw;

const VulkanContext = @import("./vk_context.zig").VulkanContext;
const VulkanSurface = @import("./vk_surface.zig").VulkanSurface;
const VulkanPhysicalDevice = @import("./vk_physical_device.zig").VulkanPhysDevice;
const VulkanLogDevice = @import("./vk_logical_device.zig").VulkanLogDevice;
const VulkanSwapchain = @import("./vk_swapchain.zig").VulkanSwapchain;
const VulkanDepth = @import("./vk_depth.zig").VulkanDepth;
const VulkanRenderpass = @import("./vk_renderpass.zig").VulkanRenderpass;
const VulkanFramebuffer = @import("./vk_framebuffer.zig").VulkanFramebuffer;
const VulkanSync = @import("./vk_sync.zig").VulkanSync;
const Window = @import("../window/window.zig").Window;

fn glfwErrorCallback(code: glfw.ErrorCode, desc: ?[*:0]const u8) callconv(.c) void {
    const message = if (desc) |msg| std.mem.span(msg) else "No GLFW error description.";
    std.log.err("GLFW error {d}: {s}", .{ code, message });
}

pub const VulkanRenderContext = struct {
    vkcontext: VulkanContext,
    vksurface: VulkanSurface,
    vkphysicaldevice: VulkanPhysicalDevice,
    vklogicaldevice: VulkanLogDevice,
    vkswapchain: VulkanSwapchain,
    vkdepth: VulkanDepth,
    vkrenderpass: VulkanRenderpass,
    vkframebuffer: VulkanFramebuffer,
    vksync: VulkanSync,
    window: Window,

    pub fn init(self: *VulkanRenderContext, allocator: std.mem.Allocator) !void {
        _ = glfw.setErrorCallback(glfwErrorCallback);
        try glfw.init();
        errdefer glfw.terminate();

        self.window = try Window.init();
        errdefer self.window.deinit();

        self.vkcontext = try VulkanContext.init();
        self.vkcontext.instance = vk.InstanceProxy.init(self.vkcontext.instance.handle, &self.vkcontext.vki);
        errdefer self.vkcontext.deinit();

        self.vksurface = try VulkanSurface.init(self.vkcontext.instance.handle, self.window.handle);
        errdefer self.vksurface.deinit(self.vkcontext.instance);

        self.vkphysicaldevice = try VulkanPhysicalDevice.init(&self.vkcontext.instance, allocator);

        self.vklogicaldevice = try VulkanLogDevice.init(self.vkcontext.instance, self.vkphysicaldevice.handle, self.vksurface.surface, allocator);
        self.vklogicaldevice.handle = vk.DeviceProxy.init(self.vklogicaldevice.handle.handle, &self.vklogicaldevice.vkd);
        errdefer self.vklogicaldevice.handle.destroyDevice(null);

        self.vkswapchain = try VulkanSwapchain.init(self.vkcontext.instance, self.vkphysicaldevice.handle, &self.vklogicaldevice.handle, self.vksurface.surface, self.window.handle, allocator);
        errdefer self.vkswapchain.deinit(self.vklogicaldevice.handle, allocator);

        self.vkdepth = try VulkanDepth.init(&self.vklogicaldevice.handle, self.vkswapchain.extent, self.vkcontext.instance, self.vkphysicaldevice.handle);
        errdefer self.vkdepth.deinit(&self.vklogicaldevice.handle);

        self.vkrenderpass = try VulkanRenderpass.init(&self.vklogicaldevice.handle, self.vkswapchain.image_format, self.vkdepth.format);
        errdefer self.vkrenderpass.deinit(&self.vklogicaldevice.handle);

        self.vkframebuffer = try VulkanFramebuffer.init(allocator, &self.vklogicaldevice.handle, self.vkrenderpass.handle, self.vkswapchain.images_view, self.vkdepth.depth_view, self.vkswapchain.extent);
        errdefer self.vkframebuffer.deinit(&self.vklogicaldevice.handle);

        self.vksync = try VulkanSync.init(&self.vklogicaldevice.handle, allocator, self.vkswapchain.images_view.len);
        errdefer self.vksync.deinit(&self.vklogicaldevice.handle);

        self.window.setIcon();
        glfw.pollEvents();
    }

    pub fn recreateSwapchain(self: *VulkanRenderContext, allocator: std.mem.Allocator) !void {
        self.vklogicaldevice.handle = vk.DeviceProxy.init(self.vklogicaldevice.handle.handle, &self.vklogicaldevice.vkd);
        self.vkcontext.instance = vk.InstanceProxy.init(self.vkcontext.instance.handle, &self.vkcontext.vki);
        _ = self.vklogicaldevice.handle.deviceWaitIdle() catch {};

        self.vkframebuffer.deinit(&self.vklogicaldevice.handle);
        self.vkdepth.deinit(&self.vklogicaldevice.handle);
        self.vksync.deinit(&self.vklogicaldevice.handle);
        self.vkswapchain.deinit(self.vklogicaldevice.handle, allocator);

        self.vkswapchain = try VulkanSwapchain.init(self.vkcontext.instance, self.vkphysicaldevice.handle, &self.vklogicaldevice.handle, self.vksurface.surface, self.window.handle, allocator);
        self.vkdepth = try VulkanDepth.init(&self.vklogicaldevice.handle, self.vkswapchain.extent, self.vkcontext.instance, self.vkphysicaldevice.handle);
        self.vksync = try VulkanSync.init(&self.vklogicaldevice.handle, allocator, self.vkswapchain.images_view.len);
        self.vkframebuffer = try VulkanFramebuffer.init(allocator, &self.vklogicaldevice.handle, self.vkrenderpass.handle, self.vkswapchain.images_view, self.vkdepth.depth_view, self.vkswapchain.extent);
    }

    pub fn deinit(self: *VulkanRenderContext, allocator: std.mem.Allocator) void {
        _ = self.vklogicaldevice.handle.deviceWaitIdle() catch {};
        self.vksync.deinit(&self.vklogicaldevice.handle);
        self.vkframebuffer.deinit(&self.vklogicaldevice.handle);
        self.vkdepth.deinit(&self.vklogicaldevice.handle);
        self.vkrenderpass.deinit(&self.vklogicaldevice.handle);
        self.vkswapchain.deinit(self.vklogicaldevice.handle, allocator);
        self.vklogicaldevice.handle.destroyDevice(null);
        self.vksurface.deinit(self.vkcontext.instance);
        self.vkcontext.deinit();
        self.window.deinit();
        glfw.terminate();
    }
};
