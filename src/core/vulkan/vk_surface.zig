const std = @import("std");
const vk = @import("../core.zig").vk;
const glfw = @import("../core.zig").glfw;

pub const VulkanSurface = struct {
    surface: vk.SurfaceKHR,

    pub fn init(instance: vk.Instance, window: *glfw.Window) !VulkanSurface {
         var surface: vk.SurfaceKHR = undefined;

        try glfw.createWindowSurface(@as(*anyopaque, @ptrFromInt(@intFromEnum(instance))), window, null, &surface);
        std.log.info("Vulkan Surface created successfully.", .{});
        return .{ .surface = surface };
    }

    pub fn deinit(self: *VulkanSurface, instance: vk.InstanceProxy) void {
        instance.destroySurfaceKHR(self.surface, null);
        std.log.info("Vulkan Surface Destroyed.", .{});
    }
};
