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

        const path = try std.fs.path.join(allocator, &.{ "engine", "assets", "models", texture_name, filename });
        defer allocator.free(path);

        var read_buffer: [4096]u8 = undefined;
        var image = try zigimg.Image.fromFilePath(allocator, io, path, &read_buffer);
        defer image.deinit(allocator);

        std.log.info("Texture Loaded: {d}x{d}", .{ image.width, image.height });

        return undefined;
    }

    pub fn deinit() void {
        
    }
};
