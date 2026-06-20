const std = @import("std");
const Io = std.Io;

pub const TPS: u64 = 60;
const NS_PER_TICK: u64 = std.time.ns_per_s / TPS;

pub fn tick(io: Io, last_tick: *?Io.Timestamp) !void {
    const now = Io.Clock.now(.awake, io);
    if (last_tick.*) |last| {
        const elapsed_ns = now.nanoseconds -| last.nanoseconds;
        if (elapsed_ns < NS_PER_TICK) {
            try io.sleep(.fromNanoseconds(NS_PER_TICK - elapsed_ns), .awake);
        }
    }
    last_tick.* = Io.Clock.now(.awake, io);
}
