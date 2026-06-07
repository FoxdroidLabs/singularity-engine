const std = @import("std");
const vk = @import("../core.zig").vk;

pub const MAX_FRAMES_IN_FLIGHT: usize = 2;

pub const VulkanSync = struct {
    image_available: [MAX_FRAMES_IN_FLIGHT]vk.Semaphore,
    render_finished: [MAX_FRAMES_IN_FLIGHT]vk.Semaphore,
    in_flight: [MAX_FRAMES_IN_FLIGHT]vk.Fence,
    current_frame: usize,

    pub fn init(logDevice: *const vk.DeviceProxy) !VulkanSync {
        var image_available: [MAX_FRAMES_IN_FLIGHT]vk.Semaphore = undefined;
        var render_finished: [MAX_FRAMES_IN_FLIGHT]vk.Semaphore = undefined;
        var in_flight: [MAX_FRAMES_IN_FLIGHT]vk.Fence = undefined;

        for (0..MAX_FRAMES_IN_FLIGHT) |i| {
            image_available[i] = try logDevice.createSemaphore(&.{}, null);
            render_finished[i] = try logDevice.createSemaphore(&.{}, null);
            in_flight[i] = try logDevice.createFence(&.{ .flags = .{ .signaled_bit = true } }, null);
        }

        std.log.info("Vulkan Sync created successfully.", .{});
        return .{
            .image_available = image_available,
            .render_finished = render_finished,
            .in_flight = in_flight,
            .current_frame = 0,
        };
    }

    pub fn deinit(self: *VulkanSync, logDevice: *const vk.DeviceProxy) void {
        for (0..MAX_FRAMES_IN_FLIGHT) |i| {
            logDevice.destroySemaphore(self.image_available[i], null);
            logDevice.destroySemaphore(self.render_finished[i], null);
            logDevice.destroyFence(self.in_flight[i], null);
        }
        std.log.info("Vulkan Sync Destroyed.", .{});
    }
};
