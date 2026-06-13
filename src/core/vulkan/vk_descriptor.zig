const std = @import("std");
const vk = @import("../core.zig").vk;
const Vub = @import("vk_uniform_buffer.zig");

pub const VulkanDescriptor = struct {
    layout: vk.DescriptorSetLayout,
    pool: vk.DescriptorPool,
    sets: []vk.DescriptorSet,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, logDevice: *const vk.DeviceProxy, uniform_buffer: *Vub.VulkanUniformBuffer, frames_in_flight: usize) !VulkanDescriptor {
        const dsl_binding = vk.DescriptorSetLayoutBinding{
            .binding = 0,
            .descriptor_type = .uniform_buffer,
            .descriptor_count = 1,
            .stage_flags = .{ .vertex_bit = true, .fragment_bit = true },
            .p_immutable_samplers = null,
        };
        const layout = try logDevice.createDescriptorSetLayout(&.{
            .binding_count = 1,
            .p_bindings = @ptrCast(&dsl_binding),
        }, null);

        const pool_size = vk.DescriptorPoolSize{
            .type = .uniform_buffer,
            .descriptor_count = @intCast(frames_in_flight),
        };
        const pool = try logDevice.createDescriptorPool(&.{
            .pool_size_count = 1,
            .p_pool_sizes = @ptrCast(&pool_size),
            .max_sets = @intCast(frames_in_flight),
        }, null);

        const layouts = try allocator.alloc(vk.DescriptorSetLayout, frames_in_flight);
        defer allocator.free(layouts);
        for (layouts) |*l| l.* = layout;

        const sets = try allocator.alloc(vk.DescriptorSet, frames_in_flight);
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
            logDevice.updateDescriptorSets(&[_]vk.WriteDescriptorSet{.{
                .dst_set = set,
                .dst_binding = 0,
                .dst_array_element = 0,
                .descriptor_type = .uniform_buffer,
                .descriptor_count = 1,
                .p_buffer_info = @ptrCast(&buf_info),
                .p_image_info = undefined,
                .p_texel_buffer_view = undefined,
            }}, &[_]vk.CopyDescriptorSet{});
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
