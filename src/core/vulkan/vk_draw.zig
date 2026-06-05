const std = @import("std");
const vk = @import("../core.zig").vk;
const VulkanCommandBuffer = @import("./vk_command_buffer.zig").VulkanCommandBuffer;

pub const VulkanDraw = struct {
    var first_draw = true;

    pub fn draw(
        logDevice: *const vk.DeviceProxy,
        swapchain: vk.SwapchainKHR,
        image_available: vk.Semaphore,
        render_finished: vk.Semaphore,
        present_queue: vk.Queue,
        graphics_queue: vk.Queue,
        cmd_buf: *VulkanCommandBuffer,
        framebuffers: []vk.Framebuffer,
        in_flight: vk.Fence,
    ) !bool {
        _ = try logDevice.waitForFences(@ptrCast(&in_flight), .true, std.math.maxInt(u64));

        const result = logDevice.acquireNextImageKHR(
            swapchain,
            std.math.maxInt(u64),
            image_available,
            .null_handle,
        ) catch |err| {
            if (err == error.OutOfDateKHR) return true;
            return err;
        };
        const image_index = result.image_index;

        try logDevice.resetFences(@ptrCast(&in_flight));

        try cmd_buf.record(logDevice, framebuffers[image_index]);

        const wait_stage = vk.PipelineStageFlags{
            .color_attachment_output_bit = true,
        };

        try logDevice.queueSubmit(graphics_queue, &[_]vk.SubmitInfo{.{
            .wait_semaphore_count = 1,
            .p_wait_semaphores = @ptrCast(&image_available),
            .p_wait_dst_stage_mask = @ptrCast(&wait_stage),
            .command_buffer_count = 1,
            .p_command_buffers = @ptrCast(&cmd_buf.cmd_buf),
            .signal_semaphore_count = 1,
            .p_signal_semaphores = @ptrCast(&render_finished),
        }}, in_flight);

        _ = logDevice.queuePresentKHR(present_queue, &.{
            .wait_semaphore_count = 1,
            .p_wait_semaphores = @ptrCast(&render_finished),
            .swapchain_count = 1,
            .p_swapchains = @ptrCast(&swapchain),
            .p_image_indices = @ptrCast(&image_index),
        }) catch |err| {
            if (err == error.OutOfDateKHR or err == error.SuboptimalKHR) return true;
            return err;
        };

        if (first_draw) {
            std.log.info("Vulkan Draw Successful.", .{});
            first_draw = false;
        }

        return false;
    }
};
