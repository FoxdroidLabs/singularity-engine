const std = @import("std");
const Io = std.Io;

var last_tick: ?Io.Timestamp = null;

pub fn tick(io: Io) !void {
    const tps = 60;
    const ns_per_tick = std.time.ns_per_s / tps;
    const now = Io.Clock.now(.awake, io);

    if (last_tick) |last| {
        const elapsed_ns = last.durationTo(now).toNanoseconds();
        if (elapsed_ns < ns_per_tick) {
            try io.sleep(.fromNanoseconds(ns_per_tick - elapsed_ns), .awake);
        }
    }
    last_tick = Io.Clock.now(.awake, io);
}