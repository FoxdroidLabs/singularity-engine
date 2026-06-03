const std = @import("std");
const ipc = @import("ipc.zig");
const presence = @import("presence.zig");

pub const Client = struct {
    fd: ipc.Fd,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, app_id: []const u8, io: std.Io) !?Client {
        var path_buf: [256]u8 = undefined;
        const path = ipc.getSocketPath(&path_buf) catch return null;
        const fd = ipc.connect(path) catch return null;
        presence.handshake(fd, allocator, app_id) catch {
            ipc.close(fd);
            return null;
        };
        io.sleep(.fromNanoseconds(500 * std.time.ns_per_ms), .awake) catch {};
        return .{ .fd = fd, .allocator = allocator };
    }

    pub fn setActivity(self: *Client, details: []const u8, state: []const u8) !void {
        try presence.setActivity(self.fd, self.allocator, details, state);
    }

    pub fn deinit(self: *Client) void {
        ipc.close(self.fd);
    }
};
