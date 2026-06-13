const std = @import("std");
const vk = @import("../core.zig").vk;
const VulkanVertexBuffer = @import("vk_vertex_buffer.zig").VulkanVertexBuffer;
const VulkanIndexBuffer = @import("vk_index_buffer.zig").VulkanIndexBuffer;

pub const Mesh = struct {
    vertex_buffer: VulkanVertexBuffer,
    index_buffer: VulkanIndexBuffer,

    pub fn load(io: std.Io, allocator: std.mem.Allocator, instance: vk.InstanceProxy, device: vk.PhysicalDevice, logDevice: *const vk.DeviceProxy, name: []const u8) !Mesh {
        const path = try std.fmt.allocPrint(allocator, "engine/assets/3D/{s}", .{name});
        defer allocator.free(path);
        return loadObj(io, allocator, instance, device, logDevice, path);
    }

    pub fn loadObj(io: std.Io, allocator: std.mem.Allocator, instance: vk.InstanceProxy, device: vk.PhysicalDevice, logDevice: *const vk.DeviceProxy, path: []const u8) !Mesh {
        const exe_dir = try std.process.executableDirPathAlloc(io, allocator);
        defer allocator.free(exe_dir);
        const full_path = try std.fs.path.join(allocator, &.{ exe_dir, path });
        defer allocator.free(full_path);

        const file = try std.Io.Dir.cwd().openFile(io, full_path, .{ .mode = .read_only });
        defer file.close(io);

        const size = (try file.stat(io)).size;
        const content = try allocator.alloc(u8, size);
        defer allocator.free(content);

        var read_buf: [4096]u8 = undefined;
        var fr = file.reader(io, &read_buf);
        _ = try fr.interface.readSliceAll(content);

        var positions = std.ArrayListUnmanaged([3]f32).empty;
        defer positions.deinit(allocator);
        var normals = std.ArrayListUnmanaged([3]f32).empty;
        defer normals.deinit(allocator);
        var vertices = std.ArrayListUnmanaged(VulkanVertexBuffer.Vertex).empty;
        defer vertices.deinit(allocator);
        var indices = std.ArrayListUnmanaged(u16).empty;
        defer indices.deinit(allocator);

        var lines = std.mem.splitScalar(u8, content, '\n');
        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \r\n");
            if (trimmed.len == 0) continue;

            if (std.mem.startsWith(u8, trimmed, "vn ")) {
                var it = std.mem.splitScalar(u8, trimmed[3..], ' ');
                const x = try std.fmt.parseFloat(f32, it.next() orelse continue);
                const y = try std.fmt.parseFloat(f32, it.next() orelse continue);
                const z = try std.fmt.parseFloat(f32, it.next() orelse continue);
                try normals.append(allocator, .{ x, y, z });
            } else if (std.mem.startsWith(u8, trimmed, "v ")) {
                var it = std.mem.splitScalar(u8, trimmed[2..], ' ');
                const x = try std.fmt.parseFloat(f32, it.next() orelse continue);
                const y = try std.fmt.parseFloat(f32, it.next() orelse continue);
                const z = try std.fmt.parseFloat(f32, it.next() orelse continue);
                try positions.append(allocator, .{ x, y, z });
            } else if (std.mem.startsWith(u8, trimmed, "f ")) {
                var it = std.mem.splitScalar(u8, trimmed[2..], ' ');
                var pos_indices: [3]u16 = undefined;
                var nor_indices: [3]u16 = undefined;
                var i: usize = 0;
                while (it.next()) |token| {
                    if (i >= 3) break;
                    var tok_it = std.mem.splitScalar(u8, token, '/');
                    const pos_str = tok_it.next() orelse continue;
                    _ = tok_it.next(); // skip uv
                    const nor_str = tok_it.next() orelse "1";
                    pos_indices[i] = (try std.fmt.parseInt(u16, pos_str, 10)) - 1;
                    nor_indices[i] = (try std.fmt.parseInt(u16, std.mem.trim(u8, nor_str, " \r\n"), 10)) - 1;
                    i += 1;
                }
                if (i == 3) {
                    for (0..3) |j| {
                        const normal = if (normals.items.len > 0) normals.items[nor_indices[j]] else [3]f32{ 0.0, 1.0, 0.0 };
                        try vertices.append(allocator, .{
                            .pos = positions.items[pos_indices[j]],
                            .color = .{ 1.0, 1.0, 1.0 },
                            .normal = normal,
                        });
                        try indices.append(allocator, @intCast(indices.items.len));
                    }
                }
            }
        }

        std.log.info("Mesh loaded: {d} vertices, {d} indices", .{ vertices.items.len, indices.items.len });
        const vb = try VulkanVertexBuffer.init(instance, device, logDevice, vertices.items);
        const ib = try VulkanIndexBuffer.init(instance, device, logDevice, indices.items);
        return .{ .vertex_buffer = vb, .index_buffer = ib };
    }

    pub fn deinit(self: *Mesh, logDevice: *const vk.DeviceProxy) void {
        self.vertex_buffer.deinit(logDevice);
        self.index_buffer.deinit(logDevice);
    }
};
