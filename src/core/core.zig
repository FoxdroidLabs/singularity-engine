const std = @import("std");
pub const vk = @import("vulkan");
pub const glfw = @import("zglfw");

pub const VulkanContext = @import("./vulkan/vk_context.zig").VulkanContext;
pub const VulkanSurface = @import("./vulkan/vk_surface.zig").VulkanSurface;
pub const VulkanPhysicalDevice = @import("./vulkan/vk_physical_device.zig").VulkanPhysDevice;
pub const VulkanLogDevice = @import("./vulkan/vk_logical_device.zig").VulkanLogDevice;
pub const VulkanSwapchain = @import("./vulkan/vk_swapchain.zig").VulkanSwapchain;
pub const VulkanRenderpass = @import("./vulkan/vk_renderpass.zig").VulkanRenderpass;
pub const Window = @import("./window/window.zig").Window;

pub const Core = struct {
    gpa: std.heap.DebugAllocator(.{}),
    vkc: VulkanContext,
    vks: VulkanSurface,
    vkphysdev: VulkanPhysicalDevice,
    vklogdev: VulkanLogDevice,
    vkswpc: VulkanSwapchain,
    vkrp: VulkanRenderpass,
    window: Window,

    pub fn init() !Core {
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
        core.window.setIcon();
        glfw.pollEvents();

        // std.log.info("Singularity Core: Core Init working", .{});
        return core;
    }

    pub fn deinit(self: *Core) void {
        const allocator = self.gpa.allocator();
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
