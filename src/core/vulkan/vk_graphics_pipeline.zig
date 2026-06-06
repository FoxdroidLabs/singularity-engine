const std = @import("std");
const vk = @import("../core.zig").vk;

pub const PipelineConfig = struct {
    shader_dir: []const u8 = "engine/shaders",
    polygon_mode: vk.PolygonMode = .fill,
    cull_mode: vk.CullModeFlags = .{},
    front_face: vk.FrontFace = .clockwise,
    topology: vk.PrimitiveTopology = .triangle_list,
};

pub const VulkanGraphicsPipeline = struct {
    pipeline: vk.Pipeline,
    layout: vk.PipelineLayout,

    fn loadShader(io: std.Io, allocator: std.mem.Allocator, path: []const u8) ![]align(4) u8 {
        const file = try std.Io.Dir.cwd().openFile(io, path, .{ .mode = .read_only });
        defer file.close(io);
        const size = (try file.stat(io)).size;
        const buf = try allocator.alignedAlloc(u8, @enumFromInt(2), size);
        errdefer allocator.free(buf);
        var read_buf: [4096]u8 = undefined;
        var fr = file.reader(io, &read_buf);
        _ = try fr.interface.readSliceAll(buf);
        return buf;
    }

    fn initShaderModules(io: std.Io, allocator: std.mem.Allocator, device: vk.DeviceProxy, shader_dir: []const u8) !struct { vert: vk.ShaderModule, frag: vk.ShaderModule } {
        const exe_dir = try std.process.executableDirPathAlloc(io, allocator);
        defer allocator.free(exe_dir);

        const vert_path = try std.fs.path.join(allocator, &.{ exe_dir, shader_dir, "main.vert.spv" });
        defer allocator.free(vert_path);
        const frag_path = try std.fs.path.join(allocator, &.{ exe_dir, shader_dir, "main.frag.spv" });
        defer allocator.free(frag_path);

        const vert_spv = try loadShader(io, allocator, vert_path);
        defer allocator.free(vert_spv);
        const frag_spv = try loadShader(io, allocator, frag_path);
        defer allocator.free(frag_spv);

        const vert_module = try device.createShaderModule(&.{
            .code_size = vert_spv.len,
            .p_code = @ptrCast(vert_spv.ptr),
        }, null);
        errdefer device.destroyShaderModule(vert_module, null);

        const frag_module = try device.createShaderModule(&.{
            .code_size = frag_spv.len,
            .p_code = @ptrCast(frag_spv.ptr),
        }, null);

        return .{ .vert = vert_module, .frag = frag_module };
    }

    pub fn init(io: std.Io, allocator: std.mem.Allocator, logDevice: *const vk.DeviceProxy, extent: vk.Extent2D, render_pass: vk.RenderPass, config: PipelineConfig) !VulkanGraphicsPipeline {
        std.log.info("Shader Stored in : {s}", .{config.shader_dir});
        const modules = try initShaderModules(io, allocator, logDevice.*, config.shader_dir);
        defer logDevice.destroyShaderModule(modules.vert, null);
        defer logDevice.destroyShaderModule(modules.frag, null);

        const pipeline_layout = try logDevice.createPipelineLayout(&.{
            .set_layout_count = 0,
            .p_set_layouts = undefined,
            .push_constant_range_count = 0,
            .p_push_constant_ranges = undefined,
        }, null);
        errdefer logDevice.destroyPipelineLayout(pipeline_layout, null);

        var pipelines: [1]vk.Pipeline = undefined;
        _ = try logDevice.createGraphicsPipelines(.null_handle, &[_]vk.GraphicsPipelineCreateInfo{.{
            .stage_count = 2,
            .p_stages = &[_]vk.PipelineShaderStageCreateInfo{
                .{
                    .stage = .{ .vertex_bit = true },
                    .module = modules.vert,
                    .p_name = "main",
                },
                .{
                    .stage = .{ .fragment_bit = true },
                    .module = modules.frag,
                    .p_name = "main",
                },
            },
            .p_vertex_input_state = &.{
                .vertex_binding_description_count = 0,
                .p_vertex_binding_descriptions = undefined,
                .vertex_attribute_description_count = 0,
                .p_vertex_attribute_descriptions = undefined,
            },
            .p_input_assembly_state = &.{
                .topology = config.topology,
                .primitive_restart_enable = .false,
            },
            .p_viewport_state = &.{
                .viewport_count = 1,
                .p_viewports = &[_]vk.Viewport{.{
                    .x = 0,
                    .y = 0,
                    .width = @floatFromInt(extent.width),
                    .height = @floatFromInt(extent.height),
                    .min_depth = 0.0,
                    .max_depth = 1.0,
                }},
                .scissor_count = 1,
                .p_scissors = &[_]vk.Rect2D{.{
                    .offset = .{ .x = 0, .y = 0 },
                    .extent = extent,
                }},
            },
            .p_rasterization_state = &.{
                .depth_clamp_enable = .false,
                .rasterizer_discard_enable = .false,
                .polygon_mode = config.polygon_mode,
                .cull_mode = config.cull_mode,
                .front_face = config.front_face,
                .depth_bias_enable = .false,
                .depth_bias_constant_factor = 0,
                .depth_bias_clamp = 0,
                .depth_bias_slope_factor = 0,
                .line_width = 1.0,
            },
            .p_multisample_state = &.{
                .rasterization_samples = .{ .@"1_bit" = true },
                .sample_shading_enable = .false,
                .min_sample_shading = 1.0,
                .alpha_to_coverage_enable = .false,
                .alpha_to_one_enable = .false,
            },
            .p_depth_stencil_state = null,
            .p_color_blend_state = &.{
                .logic_op_enable = .false,
                .logic_op = .copy,
                .attachment_count = 1,
                .p_attachments = &[_]vk.PipelineColorBlendAttachmentState{.{
                    .blend_enable = .false,
                    .src_color_blend_factor = .one,
                    .dst_color_blend_factor = .zero,
                    .color_blend_op = .add,
                    .src_alpha_blend_factor = .one,
                    .dst_alpha_blend_factor = .zero,
                    .alpha_blend_op = .add,
                    .color_write_mask = .{ .r_bit = true, .g_bit = true, .b_bit = true, .a_bit = true },
                }},
                .blend_constants = .{ 0, 0, 0, 0 },
            },
            .p_dynamic_state = null,
            .layout = pipeline_layout,
            .render_pass = render_pass,
            .subpass = 0,
            .base_pipeline_handle = .null_handle,
            .base_pipeline_index = -1,
        }}, null, &pipelines);

        std.log.info("Vulkan Graphics Pipeline created successfully.", .{});
        return .{ .pipeline = pipelines[0], .layout = pipeline_layout };
    }

    pub fn deinit(self: *VulkanGraphicsPipeline, logDevice: *const vk.DeviceProxy) void {
        logDevice.destroyPipeline(self.pipeline, null);
        logDevice.destroyPipelineLayout(self.layout, null);
        std.log.info("Vulkan Graphics Pipeline destroyed.", .{});
    }
};
