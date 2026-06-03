const std = @import("std");
const vk = @import("../core.zig").vk;
const glfw = @import("../core.zig").glfw;

pub const VulkanSwapchain = struct {
    handle: vk.SwapchainKHR,
    images: []vk.Image,
    images_view: []vk.ImageView,
    image_format: vk.Format,
    extent: vk.Extent2D,

    pub fn init(instance: vk.InstanceProxy, device: vk.PhysicalDevice, logDevice: *const vk.DeviceProxy, surface: vk.SurfaceKHR, window: *glfw.Window, allocator: std.mem.Allocator) !VulkanSwapchain {
        var surfaceFormat_count: u32 = 0;
        var presentMode_count: u32 = 0;

        const capabilities = try instance.getPhysicalDeviceSurfaceCapabilitiesKHR(device, surface);

        _ = try instance.getPhysicalDeviceSurfaceFormatsKHR(device, surface, &surfaceFormat_count, null);
        const formats = try allocator.alloc(vk.SurfaceFormatKHR, surfaceFormat_count);
        defer allocator.free(formats);
        _ = try instance.getPhysicalDeviceSurfaceFormatsKHR(device, surface, &surfaceFormat_count, formats.ptr);

        _ = try instance.getPhysicalDeviceSurfacePresentModesKHR(device, surface, &presentMode_count, null);
        const presents = try allocator.alloc(vk.PresentModeKHR, presentMode_count);
        defer allocator.free(presents);
        _ = try instance.getPhysicalDeviceSurfacePresentModesKHR(device, surface, &presentMode_count, presents.ptr);

        var chosen_format = formats[0];
        for (formats) |format| {
            if (format.format == .b8g8r8_srgb and format.color_space == .srgb_nonlinear_khr) {
                chosen_format = format;
                break;
            }
        }

        var chosen_presents = presents[0];
        for (presents) |present| {
            if (present == .mailbox_khr) {
                chosen_presents = present;
                break;
            }
        }

        const extent = if (capabilities.current_extent.width != 0xFFFFFFFF)
            capabilities.current_extent
        else blk: {
            const size = window.getFramebufferSize();
            break :blk vk.Extent2D{
                .width = std.math.clamp(@as(u32, @intCast(size[0])), capabilities.min_image_extent.width, capabilities.max_image_extent.width),
                .height = std.math.clamp(@as(u32, @intCast(size[1])), capabilities.min_image_extent.height, capabilities.max_image_extent.height),
            };
        };

        const swapchain_info = vk.SwapchainCreateInfoKHR{
            .surface = surface,
            .min_image_count = capabilities.min_image_count + 1,
            .image_format = chosen_format.format,
            .image_color_space = chosen_format.color_space,
            .image_extent = extent,
            .image_array_layers = 1,
            .image_usage = .{ .color_attachment_bit = true },
            .image_sharing_mode = .exclusive,
            .present_mode = chosen_presents,
            .pre_transform = capabilities.current_transform,
            .composite_alpha = .{ .opaque_bit_khr = true },
            .clipped = .true,
        };

        const swapchain = try logDevice.*.createSwapchainKHR(&swapchain_info, null);
        std.log.info("Vulkan Swapchain created successfully.", .{});
        const images = try logDevice.*.getSwapchainImagesAllocKHR(swapchain, allocator);

        const images_view = try allocator.alloc(vk.ImageView, images.len);
        for (images, 0..) |image, i| {
            images_view[i] = try logDevice.*.createImageView(&.{ .image = image, .view_type = .@"2d", .format = chosen_format.format, .components = .{
                .r = .identity,
                .g = .identity,
                .b = .identity,
                .a = .identity,
            }, .subresource_range = .{
                .aspect_mask = .{ .color_bit = true },
                .base_mip_level = 0,
                .level_count = 1,
                .base_array_layer = 0,
                .layer_count = 1,
            } }, null);
        }
        std.log.info("Vulkan Images created successfully.", .{});
        return .{ .handle = swapchain, .images = images, .images_view = images_view, .image_format = chosen_format.format, .extent = extent };
    }
    pub fn deinit(self: *VulkanSwapchain, logDevice: vk.DeviceProxy, allocator: std.mem.Allocator) void {
        for (self.images_view) |view| {
            logDevice.destroyImageView(view, null);
        }
        allocator.free(self.images_view);
        allocator.free(self.images);
        logDevice.destroySwapchainKHR(self.handle, null);
        std.log.info("Vulkan Swapchain Destroyed.", .{});
    }
};
