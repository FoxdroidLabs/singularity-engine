const std = @import("std");
const Io = std.Io;

pub fn tick(io: Io) !void {
    const tps = 60;
    const ns_per_tick = std.time.ns_per_s / tps;
    const start = Io.Clock.now(.awake, io);

    const elapsed_ns = start.durationTo(Io.Clock.now(.awake, io)).toNanoseconds();
    if (elapsed_ns < ns_per_tick) {
        try io.sleep(.fromNanoseconds(ns_per_tick - elapsed_ns), .awake);
    }
}
