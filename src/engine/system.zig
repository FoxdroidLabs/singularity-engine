const std = @import("std");
const Io = std.Io;
const glfw = @import("zglfw");
const tick = @import("tick.zig");
const jobs = @import("jobs.zig");
const singularity = @import("singularity");
const core = singularity.Core;
const VulkanRenderContext = singularity.VulkanRenderContext;
const Camera = @import("camera/camera.zig").Camera;

var view: [4][4]f32 = [_][4]f32{[_]f32{0} ** 4} ** 4;
var should_stop = std.atomic.Value(bool).init(false);
var mutex: Io.Mutex = .init;

fn lockSpin() void {
    while (!mutex.tryLock()) std.atomic.spinLoopHint();
}

fn renderLoop(io: std.Io, c: *core, render_context: *VulkanRenderContext, allocator: std.mem.Allocator) void {
    var last_tick: ?Io.Timestamp = null;
    while (!should_stop.load(.acquire)) {
        tick.tick(io, &last_tick) catch {};
        mutex.lockUncancelable(io);
        defer mutex.unlock(io);
        c.draw(io, allocator, render_context, view) catch |err| {
            std.log.err("draw failed: {}", .{err});
        };
    }
}

pub fn initSystem(io: std.Io, window: *glfw.Window, c: *core, render_context: *VulkanRenderContext, allocator: std.mem.Allocator) !void {
    var camera = Camera.init();
    var last_time = std.Io.Clock.now(.awake, io);
    render_context.window.handle.setInputMode(.cursor, .normal) catch {};

    const cpu_count = std.Thread.getCpuCount() catch 4;
    const pool = try jobs.JobPool.init(allocator, io, cpu_count);
    defer pool.deinit();

    const thread = try std.Thread.spawn(.{}, renderLoop, .{ io, c, render_context, allocator });
    defer {
        should_stop.store(true, .release);
        thread.join();
    }

    while (true) {
        glfw.pollEvents();
        if (window.shouldClose()) break;
        const now = std.Io.Clock.now(.awake, io);
        const dt = @as(f32, @floatFromInt(now.nanoseconds -| last_time.nanoseconds)) / 1_000_000_000.0;
        last_time = now;
        camera.update(window, dt);
        mutex.lockUncancelable(io);
        view = camera.getView().data;
        mutex.unlock(io);
    }
}
