const std = @import("std");
const glfw = @import("zglfw");
const tick = @import("tick.zig");
const core = @import("singularity").Core;

pub fn initSystem(io: std.Io, window: *glfw.Window, c: *core) !void {
    while (true) {
        glfw.pollEvents();
        if (window.shouldClose()) break;
        try tick.tick(io);
        try c.draw(io);
    }
}
