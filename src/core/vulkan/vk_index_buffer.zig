const std = @import("std");
const vk = @import("../core.zig").vk;

const findMemoryType = @import("vk_vertex_buffer.zig").findMemoryType;

pub const VulkanIndexBuffer = struct {
    buffer: vk.Buffer,
    memory: vk.DeviceMemory,
    count: u32,

    pub fn init(
        instance: vk.InstanceProxy,
        device: vk.PhysicalDevice,
        logDevice: *const vk.DeviceProxy,
        indices: []const u16,
    ) !VulkanIndexBuffer {
        const buffer = try logDevice.createBuffer(&.{
            .size = @sizeOf(u16) * indices.len,
            .usage = .{ .index_buffer_bit = true },
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
        const data = try logDevice.mapMemory(memory, 0, @sizeOf(u16) * indices.len, .{});
        const ptr: [*]u16 = @ptrCast(@alignCast(data));
        @memcpy(ptr[0..indices.len], indices);
        logDevice.unmapMemory(memory);
        std.log.info("Vulkan Index Buffer created successfully.", .{});
        return .{ .buffer = buffer, .memory = memory, .count = @intCast(indices.len) };
    }

    pub fn bind(self: *VulkanIndexBuffer, logDevice: *const vk.DeviceProxy, cmd_buf: vk.CommandBuffer) void {
        logDevice.cmdBindIndexBuffer(cmd_buf, self.buffer, 0, .uint16);
    }

    pub fn deinit(self: *VulkanIndexBuffer, logDevice: *const vk.DeviceProxy) void {
        logDevice.destroyBuffer(self.buffer, null);
        logDevice.freeMemory(self.memory, null);
        std.log.info("Vulkan Index Buffer Destroyed.", .{});
    }
};
