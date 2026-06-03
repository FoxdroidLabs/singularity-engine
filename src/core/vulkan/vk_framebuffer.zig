const std = @import("std");
const vk = @import("../core.zig").vk;
const gflw = @import("../core.zig").glfw;

pub const VulkanFramebuffer = struct {
    handle: vk.Framebuffer,
    
    pub fn init(logDevice: *const vk.DeviceProxy, render_pass: vk.RenderPass, images_view: []vk.ImageView, extent: vk.Extent2D) !VulkanFramebuffer {
        const framebuffer_info = try logDevice.*.createFramebuffer(&.{
            .render_pass = render_pass,
            .p_attachments = images_view.ptr,
            .attachment_count = @intCast(images_view.len),
            .width = extent.width,
            .height = extent.height,
            .layers = 1,
        }, null);
        std.log.info("Vulkan Framebuffer created successfully.", .{});
        return .{ .handle = framebuffer_info };
    }
    
    pub fn deinit(self: *VulkanFramebuffer, logDevice: *const vk.DeviceProxy) void {
        logDevice.destroyFramebuffer(self.handle, null);
        std.log.info("Vulkan Framebuffer Destroyed", .{});
    }
};
