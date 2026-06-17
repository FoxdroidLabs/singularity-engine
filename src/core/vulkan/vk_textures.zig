const std = @import("std");
const vk = @import("../core.zig").vk;
const zigimg = @import("../core.zig").zigimg;
const findMemoryType = @import("vk_vertex_buffer.zig").findMemoryType;

pub const Textures = struct {
    textures: vk.Image,
    textures_view: vk.ImageView,
    textures_sample: vk.Sampler,
    memory: vk.DeviceMemory,

    fn beginSingleTimeCommands(logDevice: *const vk.DeviceProxy, pool: vk.CommandPool) !vk.CommandBuffer {
        var cmd_buf: vk.CommandBuffer = undefined;
        try logDevice.allocateCommandBuffers(&.{
            .command_pool = pool,
            .level = .primary,
            .command_buffer_count = 1,
        }, @ptrCast(&cmd_buf));

        try logDevice.beginCommandBuffer(cmd_buf, &.{
            .flags = .{ .one_time_submit_bit = true },
        });

        return cmd_buf;
    }

    fn endSingleTimeCommands(logDevice: *const vk.DeviceProxy, pool: vk.CommandPool, queue: vk.Queue, cmd_buf: vk.CommandBuffer) !void {
        try logDevice.endCommandBuffer(cmd_buf);

        try logDevice.queueSubmit(queue, &[_]vk.SubmitInfo{.{
            .command_buffer_count = 1,
            .p_command_buffers = @ptrCast(&cmd_buf),
        }}, .null_handle);
        try logDevice.queueWaitIdle(queue);

        logDevice.freeCommandBuffers(pool, @ptrCast(&cmd_buf));
    }

    pub fn init(io: std.Io, instance: vk.InstanceProxy, logDevice: *const vk.DeviceProxy, device: vk.PhysicalDevice, allocator: std.mem.Allocator, texture_name: []const u8, graphics_family: u32, graphics_queue: vk.Queue) !Textures {
        const filename = try std.fmt.allocPrint(allocator, "{s}.png", .{texture_name});
        defer allocator.free(filename);

        const relative_path = try std.fs.path.join(allocator, &.{ "engine", "assets", "models", texture_name, filename });
        defer allocator.free(relative_path);

        const exe_dir = try std.process.executableDirPathAlloc(io, allocator);
        defer allocator.free(exe_dir);

        const path = try std.fs.path.join(allocator, &.{ exe_dir, relative_path });
        defer allocator.free(path);

        const file = try std.Io.Dir.cwd().openFile(io, path, .{ .mode = .read_only });
        defer file.close(io);

        const size = (try file.stat(io)).size;
        const bytes = try allocator.alloc(u8, size);
        defer allocator.free(bytes);

        var read_buffer: [4096]u8 = undefined;
        var reader = file.reader(io, &read_buffer);
        _ = try reader.interface.readSliceAll(bytes);

        var image_stream = zigimg.io.ReadStream.initMemory(bytes);
        var image = try zigimg.formats.png.PNG.readImage(allocator, &image_stream);
        defer image.deinit(allocator);

        const pixels = image.pixels.asConstBytes();
        const image_size: vk.DeviceSize = @intCast(pixels.len);

        const staging_buffer = try logDevice.createBuffer(&.{
            .size = image_size,
            .usage = .{ .transfer_src_bit = true },
            .sharing_mode = .exclusive,
        }, null);
        errdefer logDevice.destroyBuffer(staging_buffer, null);

        const mem_req = logDevice.getBufferMemoryRequirements(staging_buffer);
        const staging_memory = try logDevice.allocateMemory(&.{
            .allocation_size = mem_req.size,
            .memory_type_index = try findMemoryType(instance, device, mem_req.memory_type_bits, .{ .host_visible_bit = true, .host_coherent_bit = true }),
        }, null);
        errdefer logDevice.freeMemory(staging_memory, null);

        try logDevice.bindBufferMemory(staging_buffer, staging_memory, 0);

        const data = try logDevice.mapMemory(staging_memory, 0, image_size, .{});
        const ptr: [*]u8 = @ptrCast(data);
        @memcpy(ptr[0..pixels.len], pixels);
        logDevice.unmapMemory(staging_memory);

        const vk_image = try logDevice.createImage(&.{
            .image_type = .@"2d",
            .format = .r8g8b8a8_srgb,
            .extent = .{ .width = @intCast(image.width), .height = @intCast(image.height), .depth = 1 },
            .mip_levels = 1,
            .array_layers = 1,
            .samples = .{ .@"1_bit" = true },
            .tiling = .optimal,
            .usage = .{ .transfer_dst_bit = true, .sampled_bit = true },
            .sharing_mode = .exclusive,
            .initial_layout = .undefined,
        }, null);
        errdefer logDevice.destroyImage(vk_image, null);

        const img_mem_req = logDevice.getImageMemoryRequirements(vk_image);
        const image_memory = try logDevice.allocateMemory(&.{
            .allocation_size = img_mem_req.size,
            .memory_type_index = try findMemoryType(instance, device, img_mem_req.memory_type_bits, .{ .device_local_bit = true }),
        }, null);
        errdefer logDevice.freeMemory(image_memory, null);

        try logDevice.bindImageMemory(vk_image, image_memory, 0);

        const temp_pool = try logDevice.createCommandPool(&.{
            .queue_family_index = graphics_family,
            .flags = .{ .transient_bit = true },
        }, null);
        defer logDevice.destroyCommandPool(temp_pool, null);

        const cmd_buf = try beginSingleTimeCommands(logDevice, temp_pool);

        const barrier1 = vk.ImageMemoryBarrier{
            .old_layout = .undefined,
            .new_layout = .transfer_dst_optimal,
            .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
            .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
            .image = vk_image,
            .subresource_range = .{
                .aspect_mask = .{ .color_bit = true },
                .base_mip_level = 0,
                .level_count = 1,
                .base_array_layer = 0,
                .layer_count = 1,
            },
            .src_access_mask = .{},
            .dst_access_mask = .{ .transfer_write_bit = true },
        };

        logDevice.cmdPipelineBarrier(cmd_buf, .{ .top_of_pipe_bit = true }, .{ .transfer_bit = true }, .{}, null, null, &[_]vk.ImageMemoryBarrier{barrier1});

        logDevice.cmdCopyBufferToImage(cmd_buf, staging_buffer, vk_image, .transfer_dst_optimal, &[_]vk.BufferImageCopy{.{
            .buffer_offset = 0,
            .buffer_row_length = 0,
            .buffer_image_height = 0,
            .image_subresource = .{
                .aspect_mask = .{ .color_bit = true },
                .mip_level = 0,
                .base_array_layer = 0,
                .layer_count = 1,
            },
            .image_offset = .{ .x = 0, .y = 0, .z = 0 },
            .image_extent = .{ .width = @intCast(image.width), .height = @intCast(image.height), .depth = 1 },
        }});

        const barrier2 = vk.ImageMemoryBarrier{
            .old_layout = .transfer_dst_optimal,
            .new_layout = .shader_read_only_optimal,
            .src_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
            .dst_queue_family_index = vk.QUEUE_FAMILY_IGNORED,
            .image = vk_image,
            .subresource_range = .{
                .aspect_mask = .{ .color_bit = true },
                .base_mip_level = 0,
                .level_count = 1,
                .base_array_layer = 0,
                .layer_count = 1,
            },
            .src_access_mask = .{ .transfer_write_bit = true },
            .dst_access_mask = .{ .shader_read_bit = true },
        };

        logDevice.cmdPipelineBarrier(cmd_buf, .{ .transfer_bit = true }, .{ .fragment_shader_bit = true }, .{}, null, null, &[_]vk.ImageMemoryBarrier{barrier2});

        try endSingleTimeCommands(logDevice, temp_pool, graphics_queue, cmd_buf);
        logDevice.destroyBuffer(staging_buffer, null);
        logDevice.freeMemory(staging_memory, null);

        const image_view = try logDevice.createImageView(&.{
            .image = vk_image,
            .view_type = .@"2d",
            .format = .r8g8b8a8_srgb,
            .components = .{ .r = .identity, .g = .identity, .b = .identity, .a = .identity },
            .subresource_range = .{
                .aspect_mask = .{ .color_bit = true },
                .base_mip_level = 0,
                .level_count = 1,
                .base_array_layer = 0,
                .layer_count = 1,
            },
        }, null);
        errdefer logDevice.destroyImageView(image_view, null);

        const sampler = try logDevice.createSampler(&.{
            .mag_filter = .linear,
            .min_filter = .linear,
            .address_mode_u = .repeat,
            .address_mode_v = .repeat,
            .address_mode_w = .repeat,
            .anisotropy_enable = .false,
            .max_anisotropy = 1.0,
            .border_color = .int_opaque_black,
            .unnormalized_coordinates = .false,
            .compare_enable = .false,
            .compare_op = .always,
            .mipmap_mode = .linear,
            .mip_lod_bias = 0.0,
            .min_lod = 0.0,
            .max_lod = 0.0,
        }, null);
        errdefer logDevice.destroySampler(sampler, null);

        std.log.info("Texture Loaded: {d}x{d}", .{ image.width, image.height });
        std.log.info("Vulkan Textures created successfully.", .{});
        return .{
            .textures = vk_image,
            .textures_view = image_view,
            .textures_sample = sampler,
            .memory = image_memory,
        };
    }
    pub fn deinit(self: *Textures, logDevice: *const vk.DeviceProxy) void {
        logDevice.destroySampler(self.textures_sample, null);
        logDevice.destroyImageView(self.textures_view, null);
        logDevice.destroyImage(self.textures, null);
        logDevice.freeMemory(self.memory, null);
        std.log.info("Vulkan Texture Destroyed.", .{});
    }
};
