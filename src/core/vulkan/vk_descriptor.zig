const std = @import("std");
const vk = @import("../core.zig").vk;
const Vub = @import("vk_uniform_buffer.zig");
const Textures = @import("vk_textures.zig").Textures;

pub const VulkanDescriptor = struct {
    layout: vk.DescriptorSetLayout,
    pool: vk.DescriptorPool,
    sets: []vk.DescriptorSet,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, logDevice: *const vk.DeviceProxy, uniform_buffer: *Vub.VulkanUniformBuffer, texture: *Textures, frames_in_flight: usize) !VulkanDescriptor {
        const dsl_bindings = [_]vk.DescriptorSetLayoutBinding{
            .{
                .binding = 0,
                .descriptor_type = .uniform_buffer,
                .descriptor_count = 1,
                .stage_flags = .{ .vertex_bit = true, .fragment_bit = true },
                .p_immutable_samplers = null,
            },
            .{
                .binding = 1,
                .descriptor_type = .sampler,
                .descriptor_count = 1,
                .stage_flags = .{ .fragment_bit = true },
                .p_immutable_samplers = null,
            },
            .{
                .binding = 2,
                .descriptor_type = .sampled_image,
                .descriptor_count = 1,
                .stage_flags = .{ .fragment_bit = true },
                .p_immutable_samplers = null,
            },
        };
        const layout = try logDevice.createDescriptorSetLayout(&.{
            .binding_count = dsl_bindings.len,
            .p_bindings = &dsl_bindings,
        }, null);
        errdefer logDevice.destroyDescriptorSetLayout(layout, null);

        const pool_sizes = [_]vk.DescriptorPoolSize{
            .{ .type = .uniform_buffer, .descriptor_count = @intCast(frames_in_flight) },
            .{ .type = .sampler, .descriptor_count = @intCast(frames_in_flight) },
            .{ .type = .sampled_image, .descriptor_count = @intCast(frames_in_flight) },
        };
        const pool = try logDevice.createDescriptorPool(&.{
            .pool_size_count = pool_sizes.len,
            .p_pool_sizes = &pool_sizes,
            .max_sets = @intCast(frames_in_flight),
        }, null);
        errdefer logDevice.destroyDescriptorPool(pool, null);

        const layouts = try allocator.alloc(vk.DescriptorSetLayout, frames_in_flight);
        defer allocator.free(layouts);
        for (layouts) |*l| l.* = layout;

        const sets = try allocator.alloc(vk.DescriptorSet, frames_in_flight);
        errdefer allocator.free(sets);
        try logDevice.allocateDescriptorSets(&.{
            .descriptor_pool = pool,
            .descriptor_set_count = @intCast(frames_in_flight),
            .p_set_layouts = layouts.ptr,
        }, sets.ptr);

        for (sets, 0..) |set, i| {
            const buf_info = vk.DescriptorBufferInfo{
                .buffer = uniform_buffer.buffer,
                .offset = uniform_buffer.stride * @as(vk.DeviceSize, @intCast(i)),
                .range = @sizeOf(Vub.UBO),
            };
            const sampler_info = vk.DescriptorImageInfo{
                .sampler = texture.textures_sample,
                .image_view = .null_handle,
                .image_layout = .shader_read_only_optimal,
            };
            const image_info = vk.DescriptorImageInfo{
                .sampler = .null_handle,
                .image_view = texture.textures_view,
                .image_layout = .shader_read_only_optimal,
            };
            logDevice.updateDescriptorSets(&[_]vk.WriteDescriptorSet{
                .{
                    .dst_set = set,
                    .dst_binding = 0,
                    .dst_array_element = 0,
                    .descriptor_type = .uniform_buffer,
                    .descriptor_count = 1,
                    .p_buffer_info = @ptrCast(&buf_info),
                    .p_image_info = undefined,
                    .p_texel_buffer_view = undefined,
                },
                .{
                    .dst_set = set,
                    .dst_binding = 1,
                    .dst_array_element = 0,
                    .descriptor_type = .sampler,
                    .descriptor_count = 1,
                    .p_buffer_info = undefined,
                    .p_image_info = @ptrCast(&sampler_info),
                    .p_texel_buffer_view = undefined,
                },
                .{
                    .dst_set = set,
                    .dst_binding = 2,
                    .dst_array_element = 0,
                    .descriptor_type = .sampled_image,
                    .descriptor_count = 1,
                    .p_buffer_info = undefined,
                    .p_image_info = @ptrCast(&image_info),
                    .p_texel_buffer_view = undefined,
                },
            }, &[_]vk.CopyDescriptorSet{});
        }

        std.log.info("Vulkan Descriptor created successfully.", .{});
        return .{ .layout = layout, .pool = pool, .sets = sets, .allocator = allocator };
    }

    pub fn deinit(self: *VulkanDescriptor, logDevice: *const vk.DeviceProxy) void {
        logDevice.destroyDescriptorPool(self.pool, null);
        logDevice.destroyDescriptorSetLayout(self.layout, null);
        self.allocator.free(self.sets);
        std.log.info("Vulkan Descriptor Destroyed.", .{});
    }
};
