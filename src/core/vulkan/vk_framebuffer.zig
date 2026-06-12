const std = @import("std");
const vk = @import("../core.zig").vk;

pub const VulkanFramebuffer = struct {
    handles: []vk.Framebuffer,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, logDevice: *const vk.DeviceProxy, render_pass: vk.RenderPass, images_view: []vk.ImageView, depth_view: vk.ImageView, extent: vk.Extent2D) !VulkanFramebuffer {
        const handles = try allocator.alloc(vk.Framebuffer, images_view.len);
        for (images_view, 0..) |view, i| {
            const attachments = [_]vk.ImageView{ view, depth_view };
            handles[i] = try logDevice.createFramebuffer(&.{
                .render_pass = render_pass,
                .attachment_count = 2,
                .p_attachments = &attachments,
                .width = extent.width,
                .height = extent.height,
                .layers = 1,
            }, null);
        }
        std.log.info("Vulkan Framebuffer created successfully.", .{});
        return .{ .handles = handles, .allocator = allocator };
    }

    pub fn deinit(self: *VulkanFramebuffer, logDevice: *const vk.DeviceProxy) void {
        for (self.handles) |fb| logDevice.destroyFramebuffer(fb, null);
        self.allocator.free(self.handles);
        std.log.info("Vulkan Framebuffer Destroyed.", .{});
    }
};
