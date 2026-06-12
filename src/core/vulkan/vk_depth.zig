const std = @import("std");
const vk = @import("../core.zig").vk;
const findMemoryType = @import("vk_vertex_buffer.zig").findMemoryType;

pub fn findDepthFormat(instance: vk.InstanceProxy, device: vk.PhysicalDevice) !vk.Format {
    const candidates = [_]vk.Format{ .d32_sfloat, .d32_sfloat_s8_uint, .d24_unorm_s8_uint };
    for (candidates) |format| {
        const props = instance.getPhysicalDeviceFormatProperties(device, format);
        if (props.optimal_tiling_features.depth_stencil_attachment_bit) {
            return format;
        }
    }
    return error.NoSupportedDepthFormat;
}

pub const VulkanDepth = struct {
    depth_image: vk.Image,
    depth_view: vk.ImageView,
    depth_memory: vk.DeviceMemory,
    format: vk.Format,

    pub fn init(logDevice: *const vk.DeviceProxy, extent: vk.Extent2D, instance: vk.InstanceProxy, device: vk.PhysicalDevice) !VulkanDepth {
        const depth_format = try findDepthFormat(instance, device);
        const depth_image = try logDevice.createImage(&.{
            .image_type = .@"2d",
            .format = depth_format,
            .extent = .{ .width = extent.width, .height = extent.height, .depth = 1 },
            .mip_levels = 1,
            .array_layers = 1,
            .samples = .{ .@"1_bit" = true },
            .tiling = .optimal,
            .usage = .{ .depth_stencil_attachment_bit = true },
            .sharing_mode = .exclusive,
            .initial_layout = .undefined,
        }, null);
        const depth_mem_req = logDevice.getImageMemoryRequirements(depth_image);
        const depth_memory = try logDevice.allocateMemory(&.{
            .allocation_size = depth_mem_req.size,
            .memory_type_index = try findMemoryType(instance, device, depth_mem_req.memory_type_bits, .{ .device_local_bit = true }),
        }, null);
        try logDevice.bindImageMemory(depth_image, depth_memory, 0);
        const depth_view = try logDevice.createImageView(&.{
            .image = depth_image,
            .view_type = .@"2d",
            .format = depth_format,
            .components = .{ .r = .identity, .g = .identity, .b = .identity, .a = .identity },
            .subresource_range = .{
                .aspect_mask = .{ .depth_bit = true },
                .base_mip_level = 0,
                .level_count = 1,
                .base_array_layer = 0,
                .layer_count = 1,
            },
        }, null);
        std.log.info("Vulkan Depth created successfully.", .{});
        return .{ .depth_view = depth_view, .depth_image = depth_image, .depth_memory = depth_memory, .format = depth_format };
    }

    pub fn deinit(self: *VulkanDepth, logDevice: *const vk.DeviceProxy) void {
        logDevice.destroyImageView(self.depth_view, null);
        logDevice.destroyImage(self.depth_image, null);
        logDevice.freeMemory(self.depth_memory, null);
        std.log.info("Vulkan Depth Destroyed.", .{});
    }
};
