const std = @import("std");
const vk = @import("../core.zig").vk;

pub fn findMemoryType(instance: vk.InstanceProxy, device: vk.PhysicalDevice, type_filter: u32, props: vk.MemoryPropertyFlags) !u32 {
    const mem_props = instance.getPhysicalDeviceMemoryProperties(device);
    for (0..mem_props.memory_type_count) |i| {
        if (type_filter & (@as(u32, 1) << @intCast(i)) != 0 and
            mem_props.memory_types[i].property_flags.contains(props))
        {
            return @intCast(i);
        }
    }
    return error.NoSuitableMemoryType;
}

pub const VulkanVertexBuffer = struct {
    buffer: vk.Buffer,
    memory: vk.DeviceMemory,
    count: u32,

    pub const Vertex = struct {
        pos: [3]f32,
        color: [3]f32,
        normal: [3]f32,
        // uv: [2]f32, // for textures later
    };

    pub const binding = vk.VertexInputBindingDescription{
        .binding = 0,
        .stride = @sizeOf(Vertex),
        .input_rate = .vertex,
    };

    pub const attributes = [_]vk.VertexInputAttributeDescription{
        .{ .binding = 0, .location = 0, .format = .r32g32b32_sfloat, .offset = @offsetOf(Vertex, "pos") },
        .{ .binding = 0, .location = 1, .format = .r32g32b32_sfloat, .offset = @offsetOf(Vertex, "color") },
        .{ .binding = 0, .location = 2, .format = .r32g32b32_sfloat, .offset = @offsetOf(Vertex, "normal") },
    };

    pub fn init(
        instance: vk.InstanceProxy,
        device: vk.PhysicalDevice,
        logDevice: *const vk.DeviceProxy,
        vertices: []const Vertex,
    ) !VulkanVertexBuffer {
        const buffer = try logDevice.createBuffer(&.{
            .size = @sizeOf(Vertex) * vertices.len,
            .usage = .{ .vertex_buffer_bit = true },
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

        const data = try logDevice.mapMemory(memory, 0, @sizeOf(Vertex) * vertices.len, .{});
        const ptr: [*]Vertex = @ptrCast(@alignCast(data));
        @memcpy(ptr[0..vertices.len], vertices);
        logDevice.unmapMemory(memory);

        std.log.info("Vulkan Vertex Buffer created successfully.", .{});
        return .{ .buffer = buffer, .memory = memory, .count = @intCast(vertices.len) };
    }

    pub fn bind(self: *VulkanVertexBuffer, logDevice: *const vk.DeviceProxy, cmd_buf: vk.CommandBuffer) void {
        logDevice.cmdBindVertexBuffers(cmd_buf, 0, 1, @ptrCast(&self.buffer), &[_]vk.DeviceSize{0});
    }

    pub fn deinit(self: *VulkanVertexBuffer, logDevice: *const vk.DeviceProxy) void {
        logDevice.destroyBuffer(self.buffer, null);
        logDevice.freeMemory(self.memory, null);
        std.log.info("Vulkan Vertex Buffer Destroyed.", .{});
    }
};
