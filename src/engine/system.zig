const std = @import("std");
const clock = @import("tick.zig");
const glfw = @import("zglfw");

pub fn initSystem(io: std.Io, window: *glfw.Window) !void {
    // std.log.info("Singularity Engine: System Init Working", .{});
    try clock.tick(io, window);
}
