const std = @import("std");
const glfw = @import("zglfw");
const Io = std.Io;

pub fn tick(io: Io, window: *glfw.Window) !void {
    // Limit to 60 tick per seconds
    const tps = 60;
    const ns_per_tick = std.time.ns_per_s / tps;

    // Create the tick Clock and check if the ns_per_tick is superior to elapsed_ns to prevent crash and cpu overload
    while (true) {
        const start = Io.Clock.now(.awake, io);
        glfw.pollEvents();
        if (window.shouldClose()) break;
        // std.debug.print("Tick\n", .{});

        const elapsed = start.durationTo(Io.Clock.now(.awake, io));
        const elapsed_ns = elapsed.toNanoseconds();
        if (elapsed_ns < ns_per_tick) {
            const remaining_ns = ns_per_tick - elapsed_ns;
            try io.sleep(.fromNanoseconds(remaining_ns), .awake);
        }
    }
}
