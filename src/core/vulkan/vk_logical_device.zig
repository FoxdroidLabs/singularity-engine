const std = @import("std");
const vk = @import("../core.zig").vk;

const BaseWrapper = vk.BaseWrapper;
const device_extension = [_][*:0]const u8{vk.extensions.khr_swapchain.name};

pub const VulkanLogDevice = struct {
    vkd: vk.DeviceWrapper, 
    handle: vk.DeviceProxy,

    pub fn init(instance: vk.InstanceProxy, device: vk.PhysicalDevice, surface: vk.SurfaceKHR, allocator: std.mem.Allocator) !VulkanLogDevice {
        var logDevice_count: u32 = 0;
        instance.getPhysicalDeviceQueueFamilyProperties(device, &logDevice_count, null);

        const logDevices = try allocator.alloc(vk.QueueFamilyProperties, logDevice_count);
        defer allocator.free(logDevices);
        instance.getPhysicalDeviceQueueFamilyProperties(device, &logDevice_count, logDevices.ptr);

        var graphics_family: ?u32 = null;
        var present_family: ?u32 = null;
        for (logDevices, 0..) |logDevice, i| {
            if (logDevice.queue_flags.graphics_bit) {
                graphics_family = @intCast(i);
            }
            const present_support = try instance.getPhysicalDeviceSurfaceSupportKHR(device, @intCast(i), surface);
            if (present_support == .true) {
                present_family = @intCast(i);
            }
            if (graphics_family != null and present_family != null) break;
        }

        const priority = [_]f32{1};
        const vkldqinfo = [_]vk.DeviceQueueCreateInfo {
            .{
                .queue_family_index = graphics_family orelse return error.NoGraphicsQueue,
                .queue_count = 1,
                .p_queue_priorities = &priority,
            },
            .{
                .queue_family_index = present_family orelse return error.NoGraphicsQueue,
                .queue_count = 1,
                .p_queue_priorities = &priority,
            }
        };

        const queue_count: u32 = if (graphics_family == present_family) 1 else 2;

        const vkldcinfo = vk.DeviceCreateInfo {
            .queue_create_info_count = queue_count,
            .p_queue_create_infos = &vkldqinfo,
            .enabled_extension_count = device_extension.len,
            .pp_enabled_extension_names = &device_extension,
        };

        const vkldinfo = try instance.createDevice(device, &vkldcinfo, null);
        std.log.info("Vulkan Logical Device created successfully.", .{});

        var self = VulkanLogDevice{
            .vkd = vk.DeviceWrapper.load(vkldinfo, instance.wrapper.dispatch.vkGetDeviceProcAddr.?),
            .handle = undefined,
        };
        self.handle = vk.DeviceProxy.init(vkldinfo, &self.vkd);
        return self;
    }
};
