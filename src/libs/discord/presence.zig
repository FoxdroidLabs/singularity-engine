const std = @import("std");
const builtin = @import("builtin");
const ipc = @import("ipc.zig");

const GetSystemTimeAsFileTime = if (builtin.os.tag == .windows) struct {
    extern "kernel32" fn GetSystemTimeAsFileTime(lpSystemTimeAsFileTime: *std.os.windows.FILETIME) callconv(.winapi) void;
}.GetSystemTimeAsFileTime else void;

const GetCurrentProcessId = if (builtin.os.tag == .windows) struct {
    extern "kernel32" fn GetCurrentProcessId() callconv(.winapi) u32;
}.GetCurrentProcessId else void;

fn getTimestamp() i64 {
    return switch (builtin.os.tag) {
        .windows => blk: {
            var ft: std.os.windows.FILETIME = undefined;
            GetSystemTimeAsFileTime(&ft);
            const t: u64 = (@as(u64, ft.dwHighDateTime) << 32) | ft.dwLowDateTime;
            break :blk @intCast((t / 10_000_000) - 11644473600);
        },
        else => blk: {
            var ts: std.os.linux.timespec = undefined;
            _ = std.os.linux.clock_gettime(std.os.linux.CLOCK.REALTIME, &ts);
            break :blk ts.sec;
        },
    };
}

fn getPid() i32 {
    return switch (builtin.os.tag) {
        .windows => @intCast(GetCurrentProcessId()),
        else => @intCast(std.os.linux.getpid()),
    };
}

pub fn handshake(fd: ipc.Fd, allocator: std.mem.Allocator, app_id: []const u8) !void {
    const payload = try std.fmt.allocPrint(
        allocator,
        "{{\"v\":1,\"client_id\":\"{s}\"}}",
        .{app_id},
    );
    defer allocator.free(payload);
    try ipc.writeFrame(fd, 0, payload);
    var buf: [4096]u8 = undefined;
    const resp = try ipc.readFrame(fd, &buf);
    if (std.mem.indexOf(u8, resp, "READY") == null) {
        return error.HandshakeFailed;
    }
    std.log.info("Discord RPC Initialised", .{});
}

pub fn setActivity(
    fd: ipc.Fd,
    allocator: std.mem.Allocator,
    details: []const u8,
    state: []const u8,
) !void {
    const payload = try std.fmt.allocPrint(allocator,
        \\{{"cmd":"SET_ACTIVITY","args":{{"pid":{d},"activity":{{"details":"{s}","state":"{s}","timestamps":{{"start":{d}}}}}}},"nonce":"1"}}
    , .{ getPid(), details, state, getTimestamp() });
    defer allocator.free(payload);
    //std.debug.print("payload: {s}\n", .{payload});
    try ipc.writeFrame(fd, 1, payload);
    //var buf: [4096]u8 = undefined;
    //const resp = try ipc.readFrame(fd, &buf);
    //std.debug.print("set_activity: {s}\n", .{resp});
}
