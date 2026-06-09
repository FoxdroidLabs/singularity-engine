const std = @import("std");
const vk = @import("../core.zig").vk;
const MAX_FRAMES_IN_FLIGHT = @import("./vk_sync.zig").MAX_FRAMES_IN_FLIGHT;
const VulkanVertexBuffer = @import("./vk_vertex_buffer.zig").VulkanVertexBuffer;
const VulkanDescriptor = @import("./vk_descriptor.zig").VulkanDescriptor;

pub const VulkanCommandBuffer = struct {
    cmd_buf: [MAX_FRAMES_IN_FLIGHT]vk.CommandBuffer,
    pool: vk.CommandPool,
    render_pass: vk.RenderPass,
    pipeline: vk.Pipeline,
    pipeline_layout: vk.PipelineLayout,
    extent: vk.Extent2D,

    pub fn init(logDevice: *const vk.DeviceProxy, graphics_family: u32, render_pass: vk.RenderPass, pipeline: vk.Pipeline, pipeline_layout: vk.PipelineLayout, extent: vk.Extent2D) !VulkanCommandBuffer {
        const pool = try logDevice.createCommandPool(&.{
            .queue_family_index = graphics_family,
            .flags = .{ .reset_command_buffer_bit = true },
        }, null);
        var cmd_buf: [MAX_FRAMES_IN_FLIGHT]vk.CommandBuffer = undefined;
        try logDevice.allocateCommandBuffers(&.{
            .command_pool = pool,
            .level = .primary,
            .command_buffer_count = MAX_FRAMES_IN_FLIGHT,
        }, @ptrCast(&cmd_buf));
        std.log.info("Vulkan Command Buffer created successfully.", .{});
        return .{ .cmd_buf = cmd_buf, .pool = pool, .render_pass = render_pass, .pipeline = pipeline, .pipeline_layout = pipeline_layout, .extent = extent };
    }

    pub fn record(self: *VulkanCommandBuffer, logDevice: *const vk.DeviceProxy, framebuffer: vk.Framebuffer, frame: usize, vertex_buffer: *VulkanVertexBuffer, descriptor: *VulkanDescriptor) !void {
        const cmd = self.cmd_buf[frame];
        try logDevice.resetCommandBuffer(cmd, .{});
        try logDevice.beginCommandBuffer(cmd, &.{ .flags = .{} });
        logDevice.cmdBeginRenderPass(cmd, &.{
            .render_pass = self.render_pass,
            .framebuffer = framebuffer,
            .render_area = .{
                .offset = .{ .x = 0, .y = 0 },
                .extent = self.extent,
            },
            .clear_value_count = 1,
            .p_clear_values = &[_]vk.ClearValue{.{
                .color = .{ .float_32 = .{ 0.0, 0.0, 0.0, 1.0 } },
            }},
        }, .@"inline");
        logDevice.cmdBindPipeline(cmd, .graphics, self.pipeline);
        logDevice.cmdSetViewport(cmd, 0, &[_]vk.Viewport{.{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(self.extent.width),
            .height = @floatFromInt(self.extent.height),
            .min_depth = 0.0,
            .max_depth = 1.0,
        }});
        logDevice.cmdSetScissor(cmd, 0, &[_]vk.Rect2D{.{
            .offset = .{ .x = 0, .y = 0 },
            .extent = self.extent,
        }});
        const aspect_ratio: f32 = @as(f32, @floatFromInt(self.extent.width)) / @as(f32, @floatFromInt(self.extent.height));
        logDevice.cmdPushConstants(cmd, self.pipeline_layout, .{ .vertex_bit = true }, 0, @sizeOf(f32), @ptrCast(&aspect_ratio));
        logDevice.cmdBindVertexBuffers(cmd, 0, &[_]vk.Buffer{vertex_buffer.buffer}, &[_]vk.DeviceSize{0});
        logDevice.cmdBindDescriptorSets(cmd, .graphics, self.pipeline_layout, 0, &[_]vk.DescriptorSet{descriptor.sets[frame]}, &[_]u32{});        logDevice.cmdDraw(cmd, vertex_buffer.count, 1, 0, 0);
        logDevice.cmdEndRenderPass(cmd);
        try logDevice.endCommandBuffer(cmd);
    }

    pub fn deinit(self: *VulkanCommandBuffer, logDevice: *const vk.DeviceProxy) void {
        logDevice.freeCommandBuffers(self.pool, &self.cmd_buf);
        logDevice.destroyCommandPool(self.pool, null);
        std.log.info("Vulkan Command Buffer Destroyed.", .{});
    }
};
