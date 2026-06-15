const std = @import("std");
const vk = @import("../core.zig").vk;
const zigimg = @import("../core.zig").zigimg;
const findMemoryType = @import("vk_vertex_buffer.zig").findMemoryType;

pub const Textures = struct {
    textures: vk.ImageView,
    textures_view: vk.ImageView,
    textures_sample: vk.Sampler,
    memory: vk.DeviceMemory,

    pub fn init(io: std.Io, allocator: std.mem.Allocator, texture_name: []const u8) !Textures {
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
