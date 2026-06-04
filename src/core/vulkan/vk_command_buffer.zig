const std = @import("std");
const vk = @import("../core.zig").vk;

pub const VulkanCommandBuffer = struct {
    cmd_buf: vk.CommandBuffer,
    pool: vk.CommandPool,
    
    pub fn init(logDevice: *const vk.DeviceProxy, render_pass: vk.RenderPass, framebuffer: vk.Framebuffer, pipeline: vk.Pipeline, extent: vk.Extent2D) !VulkanCommandBuffer {
        const graphics_family: u32 = 0;
        
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

        try logDevice.beginCommandBuffer(cmd_buf, &.{
            .flags = .{ .one_time_submit_bit = true },
        });

        logDevice.cmdBeginRenderPass(cmd_buf, &.{
            .render_pass = render_pass,
            .framebuffer = framebuffer,
            .render_area = .{
                .offset = .{ .x = 0, .y = 0 },
                .extent = extent,
            },
            .clear_value_count = 1,
            .p_clear_values = &[_]vk.ClearValue{.{
                .color = .{ .float_32 = .{ 0.0, 0.0, 0.0, 1.0 } },
            }},
        }, .@"inline");

        logDevice.cmdBindPipeline(cmd_buf, .graphics, pipeline);
        logDevice.cmdDraw(cmd_buf, 3, 1, 0, 0);

        logDevice.cmdEndRenderPass(cmd_buf);
        try logDevice.endCommandBuffer(cmd_buf);
        std.log.info("Vulkan Command Buffer created successfully.", .{});
        return .{ .cmd_buf = cmd_buf, .pool = pool };
    }
    pub fn deinit(self: *VulkanCommandBuffer, logDevice: *const vk.DeviceProxy) void {
        logDevice.freeCommandBuffers(self.pool, &[1]vk.CommandBuffer{self.cmd_buf});
        logDevice.destroyCommandPool(self.pool, null);
        std.log.info("Vulkan Command Buffer Destroyed.", .{});
    }
};
