const std = @import("std");
const glfw = @import("zglfw");
const tick = @import("tick.zig");
const singularity = @import("singularity");
const core = singularity.Core;
const VulkanRenderContext = singularity.VulkanRenderContext;
const Camera = @import("camera/camera.zig").Camera;

pub fn initSystem(io: std.Io, window: *glfw.Window, c: *core, render_context: *VulkanRenderContext, allocator: std.mem.Allocator) !void {
    var camera = Camera.init();
    var last_time = std.Io.Clock.now(.awake, io);
    render_context.window.handle.setInputMode(.cursor, .normal) catch {};

    while (true) {
        glfw.pollEvents();
        if (window.shouldClose()) break;

        const now = std.Io.Clock.now(.awake, io);
        const dt = @as(f32, @floatFromInt(last_time.durationTo(now).toNanoseconds())) / 1_000_000_000.0;
        last_time = now;

        camera.update(window, dt);
        try tick.tick(io);

        try c.draw(io, allocator, render_context, camera.getView().data);
    }
}
