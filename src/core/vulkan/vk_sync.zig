const std = @import("std");
const vk = @import("../core.zig").vk;

pub const VulkanSync = struct {
    image_available: vk.Semaphore,
    render_finished: vk.Semaphore,
    in_flight: vk.Fence,
    pub fn init(logDevice: *const vk.DeviceProxy) !VulkanSync {
        const image_available = try logDevice.createSemaphore(&.{}, null);
        const render_finished = try logDevice.createSemaphore(&.{}, null);

        const in_flight = try logDevice.createFence(&.{
            .flags = .{ .signaled_bit = true },
        }, null);

        std.log.info("Vulkan Sync created successfully.", .{});
        //_ = try logDevice.waitForFences(@ptrCast(in_flight), .true, std.math.maxInt(usize));
        //try logDevice.resetFences(@ptrCast(&in_flight));

        return .{ .image_available = image_available, .render_finished = render_finished, .in_flight = in_flight };
    }
    pub fn deinit(self: *VulkanSync, logDevice: *const vk.DeviceProxy) void {
        logDevice.destroySemaphore(self.image_available, null);
        logDevice.destroySemaphore(self.render_finished, null);
        logDevice.destroyFence(self.in_flight, null);
        std.log.info("Vulkan Sync Destroyed.", .{});
    }
};
