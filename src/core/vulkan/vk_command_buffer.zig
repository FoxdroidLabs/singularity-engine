const std = @import("std");
const vk = @import("../core.zig").vk;
const MAX_FRAMES_IN_FLIGHT = @import("./vk_sync.zig").MAX_FRAMES_IN_FLIGHT;
const VulkanVertexBuffer = @import("./vk_vertex_buffer.zig").VulkanVertexBuffer;
const VulkanIndexBuffer = @import("./vk_index_buffer.zig").VulkanIndexBuffer;
const VulkanDescriptor = @import("./vk_descriptor.zig").VulkanDescriptor;

pub const DrawContentFn = *const fn (logDevice: *const vk.DeviceProxy, cmd: vk.CommandBuffer, pipeline_layout: vk.PipelineLayout, frame: usize, context: ?*anyopaque) void;

pub const DrawIndexedContext = struct {
    vertex_buffer: *VulkanVertexBuffer,
    index_buffer: *VulkanIndexBuffer,
    descriptor: *VulkanDescriptor,
};

pub const DrawVerticesContext = struct {
    vertex_buffer: *VulkanVertexBuffer,
};

pub fn drawIndexedContent(logDevice: *const vk.DeviceProxy, cmd: vk.CommandBuffer, pipeline_layout: vk.PipelineLayout, frame: usize, context: ?*anyopaque) void {
    const draw_context: *DrawIndexedContext = @ptrCast(@alignCast(context.?));
    logDevice.cmdBindVertexBuffers(cmd, 0, &[_]vk.Buffer{draw_context.vertex_buffer.buffer}, &[_]vk.DeviceSize{0});
    logDevice.cmdBindIndexBuffer(cmd, draw_context.index_buffer.buffer, 0, .uint16);
    logDevice.cmdBindDescriptorSets(cmd, .graphics, pipeline_layout, 0, &[_]vk.DescriptorSet{draw_context.descriptor.sets[frame]}, &[_]u32{});
    logDevice.cmdDrawIndexed(cmd, draw_context.index_buffer.count, 1, 0, 0, 0);
}

pub fn drawVerticesContent(logDevice: *const vk.DeviceProxy, cmd: vk.CommandBuffer, pipeline_layout: vk.PipelineLayout, frame: usize, context: ?*anyopaque) void {
    _ = pipeline_layout;
    _ = frame;
    const draw_context: *DrawVerticesContext = @ptrCast(@alignCast(context.?));
    logDevice.cmdBindVertexBuffers(cmd, 0, &[_]vk.Buffer{draw_context.vertex_buffer.buffer}, &[_]vk.DeviceSize{0});
    logDevice.cmdDraw(cmd, draw_context.vertex_buffer.count, 1, 0, 0);
}

pub const VulkanCommandBuffer = struct {
    cmd_buf: [MAX_FRAMES_IN_FLIGHT]vk.CommandBuffer,
    pool: vk.CommandPool,
    render_pass: vk.RenderPass,
    pipeline: vk.Pipeline,
    pipeline_layout: vk.PipelineLayout,
    extent: vk.Extent2D,
    clear_color: [4]f32 = .{ 0.0, 0.0, 0.0, 1.0 },

    pub fn init(logDevice: *const vk.DeviceProxy, graphics_family: u32, render_pass: vk.RenderPass, pipeline: vk.Pipeline, pipeline_layout: vk.PipelineLayout, extent: vk.Extent2D) !VulkanCommandBuffer {
        const pool = try logDevice.createCommandPool(&.{
            .queue_family_index = graphics_family,
            .flags = .{ .reset_command_buffer_bit = true },
        }, null);
        errdefer logDevice.destroyCommandPool(pool, null);

        var cmd_buf: [MAX_FRAMES_IN_FLIGHT]vk.CommandBuffer = undefined;
        try logDevice.allocateCommandBuffers(&.{
            .command_pool = pool,
            .level = .primary,
            .command_buffer_count = MAX_FRAMES_IN_FLIGHT,
        }, @ptrCast(&cmd_buf));
        std.log.info("Vulkan Command Buffer created successfully.", .{});
        return .{ .cmd_buf = cmd_buf, .pool = pool, .render_pass = render_pass, .pipeline = pipeline, .pipeline_layout = pipeline_layout, .extent = extent };
    }

    pub fn beginFrame(self: *VulkanCommandBuffer, logDevice: *const vk.DeviceProxy, framebuffer: vk.Framebuffer, frame: usize) !vk.CommandBuffer {
        const clear_values = [_]vk.ClearValue{
            .{ .color = .{ .float_32 = self.clear_color } },
            .{ .depth_stencil = .{ .depth = 1.0, .stencil = 0 } },
        };
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
            .clear_value_count = clear_values.len,
            .p_clear_values = &clear_values,
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
        return cmd;
    }

    pub fn endFrame(self: *VulkanCommandBuffer, logDevice: *const vk.DeviceProxy, cmd: vk.CommandBuffer) !void {
        _ = self;
        logDevice.cmdEndRenderPass(cmd);
        try logDevice.endCommandBuffer(cmd);
    }

    pub fn recordFrame(self: *VulkanCommandBuffer, logDevice: *const vk.DeviceProxy, framebuffer: vk.Framebuffer, frame: usize, draw_content: DrawContentFn, context: ?*anyopaque) !void {
        const cmd = try self.beginFrame(logDevice, framebuffer, frame);
        draw_content(logDevice, cmd, self.pipeline_layout, frame, context);
        try self.endFrame(logDevice, cmd);
    }

    pub fn record(self: *VulkanCommandBuffer, logDevice: *const vk.DeviceProxy, framebuffer: vk.Framebuffer, frame: usize, vertex_buffer: *VulkanVertexBuffer, index_buffer: *VulkanIndexBuffer, descriptor: *VulkanDescriptor) !void {
        var context = DrawIndexedContext{
            .vertex_buffer = vertex_buffer,
            .index_buffer = index_buffer,
            .descriptor = descriptor,
        };
        try self.recordFrame(logDevice, framebuffer, frame, drawIndexedContent, &context);
    }

    pub fn deinit(self: *VulkanCommandBuffer, logDevice: *const vk.DeviceProxy) void {
        logDevice.freeCommandBuffers(self.pool, &self.cmd_buf);
        logDevice.destroyCommandPool(self.pool, null);
        std.log.info("Vulkan Command Buffer Destroyed.", .{});
    }
};
