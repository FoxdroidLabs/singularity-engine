const std = @import("std");
const glfw = @import("zglfw");

pub const Window = struct {
    handle: *glfw.Window,
    pub const ResizeEvent = struct { width: i32, height: i32 };
    var pending_resize: ?ResizeEvent = null;

    fn framebufferSizeCallback(window: *glfw.Window, width: c_int, height: c_int) callconv(.c) void {
        _ = window;
        pending_resize = .{ .width = @intCast(width), .height = @intCast(height) };
    }

    pub fn takePendingResize(self: *Window) ?ResizeEvent {
        _ = self;
        const event = pending_resize;
        pending_resize = null;
        return event;
    }

    pub fn init() !Window {
        glfw.windowHint(.client_api, .no_api);
        const handle = try glfw.Window.create(1600, 800, "Singularity Engine", null, null);
        _ = handle.setFramebufferSizeCallback(framebufferSizeCallback);
        std.log.info("Window created successfully", .{});
        return .{ .handle = handle };
    }

    pub fn setIcon(self: *Window) void {
        const icon48 = @embedFile("icons/icon48.raw");
        const icon32 = @embedFile("icons/icon32.raw");
        const icon16 = @embedFile("icons/icon16.raw");
        self.handle.setIcon(&.{
            .{ .width = 48, .height = 48, .pixels = @constCast(icon48) },
            .{ .width = 32, .height = 32, .pixels = @constCast(icon32) },
            .{ .width = 16, .height = 16, .pixels = @constCast(icon16) },
        });
    }

    pub fn deinit(self: *Window) void {
        self.handle.destroy();
    }
};
