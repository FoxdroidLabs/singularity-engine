const std = @import("std");
const vk = @import("../core.zig").vk;

const device_extension = [_][*:0]const u8{vk.extensions.khr_swapchain.name};

const QueueFamilies = struct {
    graphics: u32,
    present: u32,
};

fn findQueueFamilies(instance: vk.InstanceProxy, device: vk.PhysicalDevice, surface: vk.SurfaceKHR, allocator: std.mem.Allocator) !QueueFamilies {
    var count: u32 = 0;
    instance.getPhysicalDeviceQueueFamilyProperties(device, &count, null);
    const queues = try allocator.alloc(vk.QueueFamilyProperties, count);
    defer allocator.free(queues);
    instance.getPhysicalDeviceQueueFamilyProperties(device, &count, queues.ptr);

    var graphics: ?u32 = null;
    var present: ?u32 = null;
    for (queues, 0..) |q, i| {
        if (q.queue_flags.graphics_bit) graphics = @intCast(i);
        const support = try instance.getPhysicalDeviceSurfaceSupportKHR(device, @intCast(i), surface);
        if (support == .true) present = @intCast(i);
        if (graphics != null and present != null) break;
    }

    return .{
        .graphics = graphics orelse return error.NoGraphicsQueue,
        .present = present orelse return error.NoPresentQueue,
    };
}

pub const VulkanLogDevice = struct {
    vkd: vk.DeviceWrapper,
    handle: vk.DeviceProxy,
    graphics_queue: vk.Queue,
    present_queue: vk.Queue,
    graphics_family: u32,
    present_family: u32,

    pub fn init(instance: vk.InstanceProxy, device: vk.PhysicalDevice, surface: vk.SurfaceKHR, allocator: std.mem.Allocator) !VulkanLogDevice {
        const families = try findQueueFamilies(instance, device, surface, allocator);

        const priority = [_]f32{1};
        const queue_infos = [_]vk.DeviceQueueCreateInfo{
            .{
                .queue_family_index = families.graphics,
                .queue_count = 1,
                .p_queue_priorities = &priority,
            },
            .{
                .queue_family_index = families.present,
                .queue_count = 1,
                .p_queue_priorities = &priority,
            },
        };
        const queue_count: u32 = if (families.graphics == families.present) 1 else 2;
        
        const features = vk.PhysicalDeviceFeatures{
            .fill_mode_non_solid = .true,
        };

        const device_info = vk.DeviceCreateInfo{
            .queue_create_info_count = queue_count,
            .p_queue_create_infos = &queue_infos,
            .enabled_extension_count = device_extension.len,
            .pp_enabled_extension_names = &device_extension,
            .p_enabled_features = &features,
        };
        const device_handle = try instance.createDevice(device, &device_info, null);
        std.log.info("Vulkan Logical Device created successfully.", .{});

        var self = VulkanLogDevice{
            .vkd = vk.DeviceWrapper.load(device_handle, instance.wrapper.dispatch.vkGetDeviceProcAddr.?),
            .handle = undefined,
            .graphics_queue = undefined,
            .present_queue = undefined,
            .graphics_family = families.graphics,
            .present_family = families.present,
        };
        self.handle = vk.DeviceProxy.init(device_handle, &self.vkd);
        self.graphics_queue = self.handle.getDeviceQueue(families.graphics, 0);
        self.present_queue = self.handle.getDeviceQueue(families.present, 0);
        return self;
    }
};
