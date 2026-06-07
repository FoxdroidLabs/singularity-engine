const std = @import("std");
const vk = @import("../core.zig").vk;

pub const VulkanCommandBuffer = struct {
    cmd_buf: vk.CommandBuffer,
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
        var cmd_buf: vk.CommandBuffer = undefined;
        try logDevice.allocateCommandBuffers(&.{
            .command_pool = pool,
            .level = .primary,
            .command_buffer_count = 1,
        }, @ptrCast(&cmd_buf));
        std.log.info("Vulkan Command Buffer created successfully.", .{});
        return .{ .cmd_buf = cmd_buf, .pool = pool, .render_pass = render_pass, .pipeline = pipeline, .pipeline_layout = pipeline_layout, .extent = extent };
    }

    pub fn record(self: *VulkanCommandBuffer, logDevice: *const vk.DeviceProxy, framebuffer: vk.Framebuffer) !void {
        try logDevice.resetCommandBuffer(self.cmd_buf, .{});
        try logDevice.beginCommandBuffer(self.cmd_buf, &.{ .flags = .{} });
        logDevice.cmdBeginRenderPass(self.cmd_buf, &.{
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
        logDevice.cmdBindPipeline(self.cmd_buf, .graphics, self.pipeline);
        logDevice.cmdSetViewport(self.cmd_buf, 0, &[_]vk.Viewport{.{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(self.extent.width),
            .height = @floatFromInt(self.extent.height),
            .min_depth = 0.0,
            .max_depth = 1.0,
        }});
        logDevice.cmdSetScissor(self.cmd_buf, 0, &[_]vk.Rect2D{.{
            .offset = .{ .x = 0, .y = 0 },
            .extent = self.extent,
        }});
        const aspect_ratio: f32 = @as(f32, @floatFromInt(self.extent.width)) / @as(f32, @floatFromInt(self.extent.height));
        logDevice.cmdPushConstants(self.cmd_buf, self.pipeline_layout, .{ .vertex_bit = true }, 0, @sizeOf(f32), @ptrCast(&aspect_ratio));
        logDevice.cmdDraw(self.cmd_buf, 3, 1, 0, 0);
        logDevice.cmdEndRenderPass(self.cmd_buf);
        try logDevice.endCommandBuffer(self.cmd_buf);
    }

    pub fn deinit(self: *VulkanCommandBuffer, logDevice: *const vk.DeviceProxy) void {
        logDevice.freeCommandBuffers(self.pool, &[1]vk.CommandBuffer{self.cmd_buf});
        logDevice.destroyCommandPool(self.pool, null);
        std.log.info("Vulkan Command Buffer Destroyed.", .{});
    }
};
