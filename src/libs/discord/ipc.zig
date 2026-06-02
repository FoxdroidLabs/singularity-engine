const std = @import("std");
const builtin = @import("builtin");

pub const Fd = switch (builtin.os.tag) {
    .windows => std.os.windows.HANDLE,
    else => i32,
};

const CreateFileW = if (builtin.os.tag == .windows) struct {
    extern "kernel32" fn CreateFileW(
        lpFileName: [*:0]const u16,
        dwDesiredAccess: u32,
        dwShareMode: u32,
        lpSecurityAttributes: ?*anyopaque,
        dwCreationDisposition: u32,
        dwFlagsAndAttributes: u32,
        hTemplateFile: ?std.os.windows.HANDLE,
    ) callconv(.winapi) std.os.windows.HANDLE;
}.CreateFileW else void;

const WriteFile = if (builtin.os.tag == .windows) struct {
    extern "kernel32" fn WriteFile(
        hFile: std.os.windows.HANDLE,
        lpBuffer: *const anyopaque,
        nNumberOfBytesToWrite: u32,
        lpNumberOfBytesWritten: ?*u32,
        lpOverlapped: ?*anyopaque,
    ) callconv(.winapi) i32;
}.WriteFile else void;

const ReadFile = if (builtin.os.tag == .windows) struct {
    extern "kernel32" fn ReadFile(
        hFile: std.os.windows.HANDLE,
        lpBuffer: *anyopaque,
        nNumberOfBytesToRead: u32,
        lpNumberOfBytesRead: ?*u32,
        lpOverlapped: ?*anyopaque,
    ) callconv(.winapi) i32;
}.ReadFile else void;

pub fn getSocketPath(buf: []u8) ![]const u8 {
    return switch (builtin.os.tag) {
        .windows => "\\\\.\\pipe\\discord-ipc-0",
        else => blk: {
            const result = std.c.getenv("XDG_RUNTIME_DIR");
            if (result) |runtime| {
                const runtime_slice = std.mem.span(runtime);
                break :blk try std.fmt.bufPrint(buf, "{s}/discord-ipc-0", .{runtime_slice});
            }
            break :blk "/tmp/discord-ipc-0";
        },
    };
}

pub fn connect(path: []const u8) !Fd {
    switch (builtin.os.tag) {
        .windows => {
            var path_w: [256:0]u16 = undefined;
            const len = std.unicode.utf8ToUtf16Le(&path_w, path) catch return error.ConnectFailed;
            path_w[len] = 0;
            const INVALID_HANDLE = @as(std.os.windows.HANDLE, @ptrFromInt(std.math.maxInt(usize)));
            const handle = CreateFileW(
                &path_w,
                0xC0000000,
                0,
                null,
                3,
                0,
                null,
            );
            if (handle == INVALID_HANDLE)
                return error.ConnectFailed;
            return handle;
        },
        else => {
            const fd = std.os.linux.socket(
                std.os.linux.AF.UNIX,
                std.os.linux.SOCK.STREAM,
                0,
            );
            if (@as(isize, @bitCast(fd)) < 0) return error.SocketFailed;
            var addr = std.mem.zeroes(std.os.linux.sockaddr.un);
            addr.family = std.os.linux.AF.UNIX;
            @memcpy(addr.path[0..path.len], path);
            const rc = std.os.linux.connect(
                @intCast(fd),
                @ptrCast(&addr),
                @sizeOf(std.os.linux.sockaddr.un),
            );
            if (@as(isize, @bitCast(rc)) != 0) return error.ConnectFailed;
            return @intCast(fd);
        },
    }
}

pub fn writeFrame(fd: Fd, opcode: u32, payload: []const u8) !void {
    var header: [8]u8 = undefined;
    std.mem.writeInt(u32, header[0..4], opcode, .little);
    std.mem.writeInt(u32, header[4..8], @intCast(payload.len), .little);
    switch (builtin.os.tag) {
        .windows => {
            var written: u32 = 0;
            _ = WriteFile(fd, &header, 8, &written, null);
            _ = WriteFile(fd, payload.ptr, @intCast(payload.len), &written, null);
        },
        else => {
            _ = std.os.linux.write(fd, &header, 8);
            _ = std.os.linux.write(fd, payload.ptr, payload.len);
        },
    }
}

pub fn readFrame(fd: Fd, buf: []u8) ![]u8 {
    var header: [8]u8 = undefined;
    switch (builtin.os.tag) {
        .windows => {
            var read: u32 = 0;
            _ = ReadFile(fd, &header, 8, &read, null);
            const len = std.mem.readInt(u32, header[4..8], .little);
            _ = ReadFile(fd, buf.ptr, len, &read, null);
            return buf[0..len];
        },
        else => {
            _ = std.os.linux.read(fd, &header, 8);
            const len = std.mem.readInt(u32, header[4..8], .little);
            _ = std.os.linux.read(fd, buf.ptr, len);
            return buf[0..len];
        },
    }
}

pub fn close(fd: Fd) void {
    switch (builtin.os.tag) {
        .windows => std.os.windows.CloseHandle(fd),
        else => _ = std.os.linux.close(fd),
    }
}
