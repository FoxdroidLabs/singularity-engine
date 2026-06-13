const std = @import("std");
const glfw = @import("zglfw");

pub const Window = struct {
    handle: *glfw.Window,
    
    // ..Just creating a window
    pub fn init() !Window {
        glfw.windowHint(.client_api, .no_api); 
        const handle = try glfw.Window.create(1600, 800, "Singularity Engine", null, null);
        std.log.info("Window created successfully", .{});
        return .{ .handle = handle };
    }

    pub fn setIcon(self: *Window) void {
        const icon48 = @embedFile("icon48.raw");
        const icon32 = @embedFile("icon32.raw");
        const icon16 = @embedFile("icon16.raw");
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
