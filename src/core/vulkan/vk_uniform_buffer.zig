const std = @import("std");
const vk = @import("../core.zig").vk;
const math = @import("../math/math.zig");
const findMemoryType = @import("vk_vertex_buffer.zig").findMemoryType;

pub const UBO = struct {
    model: [4][4]f32,
    view: [4][4]f32,
    proj: [4][4]f32,
    light_pos: [3]f32,
    _pad: f32 = 0.0, // alignement GPU
    light_color: [3]f32,
    _pad2: f32 = 0.0,
};

pub fn identityMatrix() [4][4]f32 {
    var matrix: [4][4]f32 = undefined;
    for (0..4) |i| {
        for (0..4) |j| {
            matrix[i][j] = if (i == j) 1.0 else 0.0;
        }
    }
    return matrix;
}

fn alignUp(value: vk.DeviceSize, alignment: vk.DeviceSize) vk.DeviceSize {
    if (alignment == 0) return value;
    return (value + alignment - 1) & ~(alignment - 1);
}

pub const VulkanUniformBuffer = struct {
    buffer: vk.Buffer,
    memory: vk.DeviceMemory,
    mapped: [*]u8,
    count: u32,
    stride: vk.DeviceSize,

    pub fn init(instance: vk.InstanceProxy, device: vk.PhysicalDevice, logDevice: *const vk.DeviceProxy, frames_in_flight: u32) !VulkanUniformBuffer {
        const props = instance.getPhysicalDeviceProperties(device);
        const ubo_size: vk.DeviceSize = @intCast(@sizeOf(UBO));
        const stride = alignUp(ubo_size, props.limits.min_uniform_buffer_offset_alignment);
        const buffer = try logDevice.createBuffer(&.{
            .size = stride * frames_in_flight,
            .usage = .{ .uniform_buffer_bit = true },
            .sharing_mode = .exclusive,
        }, null);

        const mem_req = logDevice.getBufferMemoryRequirements(buffer);
        const memory = try logDevice.allocateMemory(&.{
            .allocation_size = mem_req.size,
            .memory_type_index = try findMemoryType(
                instance,
                device,
                mem_req.memory_type_bits,
                .{ .host_visible_bit = true, .host_coherent_bit = true },
            ),
        }, null);

        try logDevice.bindBufferMemory(buffer, memory, 0);

        const data = try logDevice.mapMemory(memory, 0, vk.WHOLE_SIZE, .{});
        const mapped: [*]u8 = @ptrCast(data);

        const identity = UBO{
            .model = identityMatrix(),
            .view = identityMatrix(),
            .proj = identityMatrix(),
            .light_pos = .{ 2.0, 2.0, 2.0 },
            .light_color = .{ 1.0, 1.0, 1.0 },
        };
        for (0..frames_in_flight) |i| {
            const offset: usize = @intCast(stride * @as(vk.DeviceSize, @intCast(i)));
            const ptr: *UBO = @ptrCast(@alignCast(mapped + offset));
            ptr.* = identity;
        }

        std.log.info("Vulkan Uniform Buffer created successfully.", .{});
        return .{
            .buffer = buffer,
            .memory = memory,
            .mapped = mapped,
            .count = frames_in_flight,
            .stride = stride,
        };
    }

    pub fn update(self: *VulkanUniformBuffer, frame_index: u32, ubo: UBO) void {
        const offset: usize = @intCast(self.stride * @as(vk.DeviceSize, @intCast(frame_index)));
        const ptr: *UBO = @ptrCast(@alignCast(self.mapped + offset));
        ptr.* = ubo;
    }

    pub fn deinit(self: *VulkanUniformBuffer, logDevice: *const vk.DeviceProxy) void {
        logDevice.unmapMemory(self.memory);
        logDevice.destroyBuffer(self.buffer, null);
        logDevice.freeMemory(self.memory, null);
        std.log.info("Vulkan Uniform Buffer Destroyed.", .{});
    }
};
