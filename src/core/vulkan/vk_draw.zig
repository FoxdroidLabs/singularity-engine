const std = @import("std");
const vk = @import("../core.zig").vk;
const VulkanCommandBuffer = @import("./vk_command_buffer.zig").VulkanCommandBuffer;
const VulkanSync = @import("./vk_sync.zig").VulkanSync;
const VulkanVertexBuffer = @import("./vk_vertex_buffer.zig").VulkanVertexBuffer;
const VulkanDescriptor = @import("./vk_descriptor.zig").VulkanDescriptor;

pub const VulkanDraw = struct {
    var first_draw = true;

    pub fn draw(
        logDevice: *const vk.DeviceProxy,
        swapchain: vk.SwapchainKHR,
        sync: *VulkanSync,
        present_queue: vk.Queue,
        graphics_queue: vk.Queue,
        cmd_buf: *VulkanCommandBuffer,
        framebuffers: []vk.Framebuffer,
        vertex_buffer: *VulkanVertexBuffer,
        descriptor: *VulkanDescriptor,
    ) !bool {
        const frame = sync.current_frame;
        _ = try logDevice.waitForFences(@ptrCast(&sync.in_flight[frame]), .true, std.math.maxInt(u64));
        const result = logDevice.acquireNextImageKHR(
            swapchain,
            std.math.maxInt(u64),
            sync.image_available[frame],
            .null_handle,
        ) catch |err| {
            if (err == error.OutOfDateKHR) return true;
            return err;
        };
        const image_index = result.image_index;
        try logDevice.resetFences(@ptrCast(&sync.in_flight[frame]));
        try cmd_buf.record(logDevice, framebuffers[image_index], frame, vertex_buffer, descriptor);
        const wait_stage = vk.PipelineStageFlags{ .color_attachment_output_bit = true };
        try logDevice.queueSubmit(graphics_queue, &[_]vk.SubmitInfo{.{
            .wait_semaphore_count = 1,
            .p_wait_semaphores = @ptrCast(&sync.image_available[frame]),
            .p_wait_dst_stage_mask = @ptrCast(&wait_stage),
            .command_buffer_count = 1,
            .p_command_buffers = @ptrCast(&cmd_buf.cmd_buf[frame]),
            .signal_semaphore_count = 1,
            .p_signal_semaphores = @ptrCast(&sync.render_finished[image_index]),
        }}, sync.in_flight[frame]);
        _ = logDevice.queuePresentKHR(present_queue, &.{
            .wait_semaphore_count = 1,
            .p_wait_semaphores = @ptrCast(&sync.render_finished[image_index]),
            .swapchain_count = 1,
            .p_swapchains = @ptrCast(&swapchain),
            .p_image_indices = @ptrCast(&image_index),
        }) catch |err| {
            if (err == error.OutOfDateKHR or err == error.SuboptimalKHR) return true;
            return err;
        };
        sync.current_frame = (sync.current_frame + 1) % @import("./vk_sync.zig").MAX_FRAMES_IN_FLIGHT;
        if (first_draw) {
            std.log.info("Vulkan Draw Successful.", .{});
            first_draw = false;
        }
        return false;
    }
};
