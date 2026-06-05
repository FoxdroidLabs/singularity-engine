const std = @import("std");
const vk = @import("../core.zig").vk;

pub const VulkanDraw = struct {
    pub fn draw(logDevice: *const vk.DeviceProxy, swapchain: vk.SwapchainKHR, image_available: vk.Semaphore, render_finished: vk.Semaphore, present_queue: vk.Queue, graphics_queue: vk.Queue, cmd_buf: vk.CommandBuffer, in_flight: vk.Fence) !void {
        _ = try logDevice.waitForFences(@ptrCast(&in_flight), .true, std.math.maxInt(u64));
        try logDevice.resetFences(@ptrCast(&in_flight));
        const result = try logDevice.acquireNextImageKHR(swapchain, std.math.maxInt(u64), image_available, .null_handle);
        const image_index = result.image_index;
        const wait_stage = vk.PipelineStageFlags{ .color_attachment_output_bit = true };
        try logDevice.queueSubmit(graphics_queue, &[_]vk.SubmitInfo{.{
            .wait_semaphore_count = 1,
            .p_wait_semaphores = @ptrCast(&image_available),
            .p_wait_dst_stage_mask = @ptrCast(&wait_stage),
            .command_buffer_count = 1,
            .p_command_buffers = @ptrCast(&cmd_buf),
            .signal_semaphore_count = 1,
            .p_signal_semaphores = @ptrCast(&render_finished),
        }}, in_flight);
        _ = try logDevice.queuePresentKHR(present_queue, &.{
            .wait_semaphore_count = 1,
            .p_wait_semaphores = @ptrCast(&render_finished),
            .swapchain_count = 1,
            .p_swapchains = @ptrCast(&swapchain),
            .p_image_indices = @ptrCast(&image_index),
        });
        std.log.info("Vulkan Draw Successfull.", .{});
    }
};
