const std = @import("std");
const vk = @import("../core.zig").vk;
const glfw = @import("../core.zig").glfw;

pub const VulkanRenderpass = struct {
    handle: vk.RenderPass,

    pub fn init(logDevice: *const vk.DeviceProxy, format: vk.Format) !VulkanRenderpass {
        const renderpass_info = try logDevice.*.createRenderPass(&.{
            .attachment_count = 1,
            .p_attachments = &[_]vk.AttachmentDescription{.{
                .format = format,
                .samples = .{ .@"1_bit" = true },
                .load_op = .clear,
                .store_op = .store,
                .stencil_load_op = .dont_care,
                .stencil_store_op = .dont_care,
                .initial_layout = .undefined,
                .final_layout = .present_src_khr,
            }},
            .subpass_count = 1,
            .p_subpasses = &[_]vk.SubpassDescription{.{
                .pipeline_bind_point = .graphics,
                .color_attachment_count = 1,
                .p_color_attachments = &[_]vk.AttachmentReference{.{
                    .attachment = 0,
                    .layout = .color_attachment_optimal,
                }},
            }},
            .dependency_count = 1,
            .p_dependencies = &[_]vk.SubpassDependency{.{
                .src_subpass = vk.SUBPASS_EXTERNAL,
                .dst_subpass = 0,
                .src_stage_mask = .{ .color_attachment_output_bit = true },
                .src_access_mask = .{},
                .dst_stage_mask = .{ .color_attachment_output_bit = true },
                .dst_access_mask = .{ .color_attachment_write_bit = true },
            }},
        }, null);
        std.log.info("Vulkan Renderpass created successfully.", .{});
        return .{ .handle = renderpass_info };
    }

    pub fn deinit(self: *VulkanRenderpass, logDevice: *const vk.DeviceProxy) void {
        logDevice.destroyRenderPass(self.handle, null);
        std.log.info("Vulkan Renderpass Destroyed.", .{});
    }
};
