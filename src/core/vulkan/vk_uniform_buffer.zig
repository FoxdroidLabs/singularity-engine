const std = @import("std");
const vk = @import("../core.zig").vk;
const findMemoryType = @import("vk_vertex_buffer.zig").findMemoryType;

pub const UBO = struct {
    model: [4][4]f32,
    view: [4][4]f32,
    proj: [4][4]f32,
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

pub const VulkanUniformBuffer = struct {
    buffer: vk.Buffer,
    memory: vk.DeviceMemory,
    mapped: [*]UBO,
    count: u32,

    pub fn init(instance: vk.InstanceProxy, device: vk.PhysicalDevice, logDevice: *const vk.DeviceProxy, frames_in_flight: u32) !VulkanUniformBuffer {
        const buffer = try logDevice.createBuffer(&.{
            .size = @sizeOf(UBO) * frames_in_flight,
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
        const mapped: [*]UBO = @ptrCast(@alignCast(data));

        const identity = UBO{
            .model = identityMatrix(),
            .view = identityMatrix(),
            .proj = identityMatrix(),
        };
        for (0..frames_in_flight) |i| {
            mapped[i] = identity;
        }

        std.log.info("Vulkan Uniform Buffer created successfully.", .{});
        return .{
            .buffer = buffer,
            .memory = memory,
            .mapped = mapped,
            .count = frames_in_flight,
        };
    }

    pub fn update(self: *VulkanUniformBuffer, frame_index: u32, ubo: UBO) void {
        self.mapped[frame_index] = ubo;
    }

    pub fn deinit(self: *VulkanUniformBuffer, logDevice: *const vk.DeviceProxy) void {
        logDevice.unmapMemory(self.memory);
        logDevice.destroyBuffer(self.buffer, null);
        logDevice.freeMemory(self.memory, null);
        std.log.info("Vulkan Uniform Buffer Destroyed.", .{});
    }
};
