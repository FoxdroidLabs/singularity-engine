const std = @import("std");
const vk = @import("../core.zig").vk;

pub const VulkanPhysDevice = struct {
    handle: vk.PhysicalDevice,

    pub fn init(instance: *const vk.InstanceProxy, allocator: std.mem.Allocator) !VulkanPhysDevice {

        var device_count: u32 = 0;
        _ = try instance.enumeratePhysicalDevices(&device_count, null);
        if (device_count == 0) {
            std.log.err("No Vulkan GPU found.", .{});
            return error.NoGPUFound;
        }

        const devices = try allocator.alloc(vk.PhysicalDevice, device_count);
        defer allocator.free(devices);
        _ = try instance.enumeratePhysicalDevices(&device_count, devices.ptr);
        std.log.info("Vulkan Physical Device number: {d}", .{device_count});

        for (devices, 0..) |device, i| {
            const props = instance.getPhysicalDeviceProperties(device);
            const mem_props = instance.getPhysicalDeviceMemoryProperties(device);
            const device_type = switch (props.device_type) {
                .discrete_gpu => "Discrete GPU",
                .integrated_gpu => "Integrated GPU",
                .virtual_gpu => "Virtual GPU",
                .cpu => "CPU",
                else => "Unknown",
            };
            var vram_mb: u64 = 0;
            for (mem_props.memory_heaps[0..mem_props.memory_heap_count]) |heap| {
                if (heap.flags.device_local_bit) vram_mb += heap.size / (1024 * 1024);
            }
            const api = @as(vk.Version, @bitCast(props.api_version));
            std.debug.print("   Device Index : {d}\n", .{i});
            std.debug.print("   GPU: {s}\n", .{props.device_name});
            std.debug.print("   Device Type: {s}\n", .{device_type});
            std.debug.print("   VRAM: {d} MB\n", .{vram_mb});
            std.debug.print("   Vulkan API Version: : {d}.{d}.{d}\n", .{ api.major, api.minor, api.patch });
        }
        var choseGPU: ?vk.PhysicalDevice = null;
        for (devices) |device| {
            const props = instance.getPhysicalDeviceProperties(device);
            if (props.device_type == .discrete_gpu) {
                choseGPU = device;
                break;
            }
            if (choseGPU == null) choseGPU = device;
        }
        return .{ .handle = choseGPU orelse return error.NoGPUFound };
    }
};
