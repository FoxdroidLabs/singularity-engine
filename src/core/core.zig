const std = @import("std");
pub const vk = @import("vulkan");
pub const glfw = @import("zglfw");

pub const VulkanContext = @import("./vulkan/vk_context.zig").VulkanContext;
pub const VulkanSurface = @import("./vulkan/vk_surface.zig").VulkanSurface;
pub const VulkanPhysicalDevice = @import("./vulkan/vk_physical_device.zig").VulkanPhysDevice;
pub const VulkanLogDevice = @import("./vulkan/vk_logical_device.zig").VulkanLogDevice;
pub const VulkanSwapchain = @import("./vulkan/vk_swapchain.zig").VulkanSwapchain;
pub const VulkanRenderpass = @import("./vulkan/vk_renderpass.zig").VulkanRenderpass;
pub const VulkanFramebuffer = @import("./vulkan/vk_framebuffer.zig").VulkanFramebuffer;
pub const VulkanGraphicsPipeline = @import("./vulkan/vk_graphics_pipeline.zig").VulkanGraphicsPipeline;
pub const VulkanCommandBuffer = @import("./vulkan/vk_command_buffer.zig").VulkanCommandBuffer;
pub const VulkanSync = @import("./vulkan/vk_sync.zig").VulkanSync;
pub const VulkanDraw = @import("./vulkan/vk_draw.zig").VulkanDraw;
pub const Window = @import("./window/window.zig").Window;

pub const Core = struct {
    gpa: std.heap.DebugAllocator(.{}),
    vkc: VulkanContext,
    vks: VulkanSurface,
    vkphysdev: VulkanPhysicalDevice,
    vklogdev: VulkanLogDevice,
    vkswpc: VulkanSwapchain,
    vkrp: VulkanRenderpass,
    vkfb: VulkanFramebuffer,
    vkgp: VulkanGraphicsPipeline,
    vkcb: VulkanCommandBuffer,
    vksc: VulkanSync,
    window: Window,

    pub fn init(io: std.Io) !Core {
        var core: Core = undefined;
        core.gpa = .{};
        const allocator = core.gpa.allocator();
        try glfw.init();

        core.vkc = try VulkanContext.init();
        core.vkc.instance = vk.InstanceProxy.init(core.vkc.instance.handle, &core.vkc.vki);
        core.window = try Window.init();
        core.vks = try VulkanSurface.init(core.vkc.instance.handle, core.window.handle);
        core.vkphysdev = try VulkanPhysicalDevice.init(&core.vkc.instance, allocator);
        core.vklogdev = try VulkanLogDevice.init(core.vkc.instance, core.vkphysdev.handle, core.vks.surface, allocator);
        core.vklogdev.handle = vk.DeviceProxy.init(core.vklogdev.handle.handle, &core.vklogdev.vkd);
        core.vkswpc = try VulkanSwapchain.init(core.vkc.instance, core.vkphysdev.handle, &core.vklogdev.handle, core.vks.surface, core.window.handle, allocator);
        core.vkrp = try VulkanRenderpass.init(&core.vklogdev.handle, core.vkswpc.image_format);
        core.vkfb = try VulkanFramebuffer.init(allocator, &core.vklogdev.handle, core.vkrp.handle, core.vkswpc.images_view, core.vkswpc.extent);
        core.vkgp = try VulkanGraphicsPipeline.init(io, allocator, &core.vklogdev.handle, core.vkswpc.extent, core.vkrp.handle);
        core.vkcb = try VulkanCommandBuffer.init(&core.vklogdev.handle, core.vklogdev.graphics_family, core.vkrp.handle, core.vkgp.pipeline, core.vkswpc.extent);
        core.vksc = try VulkanSync.init(&core.vklogdev.handle);
        core.window.setIcon();
        glfw.pollEvents();
        return core;
    }

    pub fn recreateSwapchain(self: *Core, io: std.Io) !void {
        const allocator = self.gpa.allocator();
        _ = self.vklogdev.handle.deviceWaitIdle() catch {};

        self.vkcb.deinit(&self.vklogdev.handle);
        self.vkfb.deinit(&self.vklogdev.handle);
        self.vkgp.deinit(&self.vklogdev.handle);
        self.vkswpc.deinit(self.vklogdev.handle, allocator);

        self.vkswpc = try VulkanSwapchain.init(self.vkc.instance, self.vkphysdev.handle, &self.vklogdev.handle, self.vks.surface, self.window.handle, allocator);
        self.vkgp = try VulkanGraphicsPipeline.init(io, allocator, &self.vklogdev.handle, self.vkswpc.extent, self.vkrp.handle);
        self.vkfb = try VulkanFramebuffer.init(allocator, &self.vklogdev.handle, self.vkrp.handle, self.vkswpc.images_view, self.vkswpc.extent);
        self.vkcb = try VulkanCommandBuffer.init(&self.vklogdev.handle, self.vklogdev.graphics_family, self.vkrp.handle, self.vkgp.pipeline, self.vkswpc.extent);
    }

    pub fn draw(self: *Core, io: std.Io) !void {
        const needs_recreate = try VulkanDraw.draw(
            &self.vklogdev.handle,
            self.vkswpc.handle,
            self.vksc.image_available,
            self.vksc.render_finished,
            self.vklogdev.present_queue,
            self.vklogdev.graphics_queue,
            &self.vkcb,
            self.vkfb.handles,
            self.vksc.in_flight,
        );
        if (needs_recreate) try self.recreateSwapchain(io);
    }

    pub fn deinit(self: *Core) void {
        const allocator = self.gpa.allocator();
        _ = self.vklogdev.handle.deviceWaitIdle() catch {};
        self.vksc.deinit(&self.vklogdev.handle);
        self.vkcb.deinit(&self.vklogdev.handle);
        self.vkgp.deinit(&self.vklogdev.handle);
        self.vkfb.deinit(&self.vklogdev.handle);
        self.vkrp.deinit(&self.vklogdev.handle);
        self.vkswpc.deinit(self.vklogdev.handle, allocator);
        self.vklogdev.handle.destroyDevice(null);
        self.vks.deinit(self.vkc.instance);
        self.vkc.deinit();
        self.window.deinit();
        glfw.terminate();
        _ = self.gpa.deinit();
    }
};
