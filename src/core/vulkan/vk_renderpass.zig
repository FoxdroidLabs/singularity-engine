const std = @import("std");
const vk = @import("../core.zig").vk;

pub const VulkanRenderpass = struct {
    handle: vk.RenderPass,

    pub fn init(logDevice: *const vk.DeviceProxy, format: vk.Format, depth_format: vk.Format) !VulkanRenderpass {
        const renderpass_info = try logDevice.*.createRenderPass(&.{
            .attachment_count = 2,
            .p_attachments = &[_]vk.AttachmentDescription{
                .{
                    .format = format,
                    .samples = .{ .@"1_bit" = true },
                    .load_op = .clear,
                    .store_op = .store,
                    .stencil_load_op = .dont_care,
                    .stencil_store_op = .dont_care,
                    .initial_layout = .undefined,
                    .final_layout = .present_src_khr,
                },
                .{
                    .format = depth_format,
                    .samples = .{ .@"1_bit" = true },
                    .load_op = .clear,
                    .store_op = .dont_care,
                    .stencil_load_op = .dont_care,
                    .stencil_store_op = .dont_care,
                    .initial_layout = .undefined,
                    .final_layout = .depth_stencil_attachment_optimal,
                },
            },
            .subpass_count = 1,
            .p_subpasses = &[_]vk.SubpassDescription{.{
                .pipeline_bind_point = .graphics,
                .color_attachment_count = 1,
                .p_color_attachments = &[_]vk.AttachmentReference{.{
                    .attachment = 0,
                    .layout = .color_attachment_optimal,
                }},
                .p_depth_stencil_attachment = &vk.AttachmentReference{
                    .attachment = 1,
                    .layout = .depth_stencil_attachment_optimal,
                },
            }},
            .dependency_count = 1,
            .p_dependencies = &[_]vk.SubpassDependency{.{
                .src_subpass = vk.SUBPASS_EXTERNAL,
                .dst_subpass = 0,
                .src_stage_mask = .{ .color_attachment_output_bit = true, .early_fragment_tests_bit = true },
                .src_access_mask = .{},
                .dst_stage_mask = .{ .color_attachment_output_bit = true, .early_fragment_tests_bit = true },
                .dst_access_mask = .{ .color_attachment_write_bit = true, .depth_stencil_attachment_write_bit = true },
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
