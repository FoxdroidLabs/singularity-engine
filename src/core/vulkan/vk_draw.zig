const std = @import("std");
const vk = @import("../core.zig").vk;
const math = @import("../math/math.zig");
const VulkanCommandBuffer = @import("./vk_command_buffer.zig").VulkanCommandBuffer;
const VulkanSync = @import("./vk_sync.zig").VulkanSync;
const VulkanVertexBuffer = @import("./vk_vertex_buffer.zig").VulkanVertexBuffer;
const VulkanIndexBuffer = @import("./vk_index_buffer.zig").VulkanIndexBuffer;
const VulkanDescriptor = @import("./vk_descriptor.zig").VulkanDescriptor;
const VulkanUniformBuffer = @import("./vk_uniform_buffer.zig").VulkanUniformBuffer;

pub const VulkanDraw = struct {
    var first_draw = true;

    pub fn draw(logDevice: *const vk.DeviceProxy, swapchain: vk.SwapchainKHR, sync: *VulkanSync, present_queue: vk.Queue, graphics_queue: vk.Queue, cmd_buf: *VulkanCommandBuffer, framebuffers: []vk.Framebuffer, vertex_buffer: *VulkanVertexBuffer, index_buffer: *VulkanIndexBuffer, uniform_buffer: *VulkanUniformBuffer, descriptor: *VulkanDescriptor, elapsed: f32) !bool {
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
        // Update UBO
        const aspect = @as(f32, @floatFromInt(cmd_buf.extent.width)) / @as(f32, @floatFromInt(cmd_buf.extent.height));
        const m = math.Matrix4;
        const model = m.rotationY(elapsed);
        const view = m.lookAt(
            .{ .x = 1.6, .y = 1.4, .z = 2.6 },
            .{ .x = 0.0, .y = 0.0, .z = 0.0 },
            .{ .x = 0.0, .y = 1.0, .z = 0.0 },
        );
        const proj = m.perspective(std.math.pi / 3.0, aspect, 0.1, 10.0);
        uniform_buffer.update(@intCast(frame), .{
            .model = model.data,
            .view = view.data,
            .proj = proj.data,
        });
        try cmd_buf.record(logDevice, framebuffers[image_index], frame, vertex_buffer, index_buffer, descriptor);
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
