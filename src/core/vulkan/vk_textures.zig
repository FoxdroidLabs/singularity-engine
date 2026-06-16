const std = @import("std");
const vk = @import("../core.zig").vk;
const zigimg = @import("../core.zig").zigimg;
const findMemoryType = @import("vk_vertex_buffer.zig").findMemoryType;
pub const Textures = struct {
    textures: vk.ImageView,
    textures_view: vk.ImageView,
    textures_sample: vk.Sampler,
    memory: vk.DeviceMemory,
    pub fn init(io: std.Io, instance: vk.InstanceProxy, logDevice: *const vk.DeviceProxy, device: vk.PhysicalDevice, allocator: std.mem.Allocator, texture_name: []const u8) !Textures {
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
            .mip_level = 1,
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

        std.log.info("Texture Loaded: {d}x{d}", .{ image.width, image.height });
        return .{
            .textures = .null_handle,
            .textures_view = .null_handle,
            .textures_sample = .null_handle,
            .memory = .null_handle,
        };
    }
    pub fn deinit() void {}
};
