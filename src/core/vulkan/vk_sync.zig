const std = @import("std");
const vk = @import("../core.zig").vk;

pub const MAX_FRAMES_IN_FLIGHT: usize = 2;

pub const VulkanSync = struct {
    image_available: []vk.Semaphore,
    render_finished: []vk.Semaphore,
    in_flight: [MAX_FRAMES_IN_FLIGHT]vk.Fence,
    current_frame: usize,
    allocator: std.mem.Allocator,

    pub fn init(logDevice: *const vk.DeviceProxy, allocator: std.mem.Allocator, image_count: usize) !VulkanSync {
        const image_available = try allocator.alloc(vk.Semaphore, image_count);
        errdefer allocator.free(image_available);

        const render_finished = try allocator.alloc(vk.Semaphore, image_count);
        errdefer allocator.free(render_finished);

        var created_sem: usize = 0;
        errdefer for (0..created_sem) |i| {
            logDevice.destroySemaphore(image_available[i], null);
            logDevice.destroySemaphore(render_finished[i], null);
        };

        for (0..image_count) |i| {
            image_available[i] = try logDevice.createSemaphore(&.{}, null);
            render_finished[i] = try logDevice.createSemaphore(&.{}, null);
            created_sem += 1;
        }

        var in_flight: [MAX_FRAMES_IN_FLIGHT]vk.Fence = undefined;
        var created_fence: usize = 0;
        errdefer for (0..created_fence) |i| logDevice.destroyFence(in_flight[i], null);

        for (0..MAX_FRAMES_IN_FLIGHT) |i| {
            in_flight[i] = try logDevice.createFence(&.{ .flags = .{ .signaled_bit = true } }, null);
            created_fence += 1;
        }

        std.log.info("Vulkan Sync created successfully.", .{});
        return .{
            .image_available = image_available,
            .render_finished = render_finished,
            .in_flight = in_flight,
            .current_frame = 0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *VulkanSync, logDevice: *const vk.DeviceProxy) void {
        for (self.image_available) |s| logDevice.destroySemaphore(s, null);
        for (self.render_finished) |s| logDevice.destroySemaphore(s, null);
        self.allocator.free(self.image_available);
        self.allocator.free(self.render_finished);
        for (0..MAX_FRAMES_IN_FLIGHT) |i| {
            logDevice.destroyFence(self.in_flight[i], null);
        }
        std.log.info("Vulkan Sync Destroyed.", .{});
    }
};
