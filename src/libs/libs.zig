const std = @import("std");
pub const discord = @import("discord/discord.zig");

var discord_client: ?discord.Client = null;
var discord_connected: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);
var discord_stop: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);

pub fn initLibs(allocator: std.mem.Allocator, io: std.Io) !void {
    // std.log.info("Singularity Libs: Libs Init Working", .{});
    discord_client = try discord.Client.init(allocator, "1393164834329202769", io);
    if (discord_client != null) {
        discord_connected.store(true, .release);
        try setActivity("In Development", "FV-A.0.0.1");
    } else {
        (try std.Thread.spawn(.{}, discordRetryLoop, .{ allocator, io })).detach();
    }
}

fn discordRetryLoop(allocator: std.mem.Allocator, io: std.Io) void {
    while (!discord_stop.load(.acquire)) {
        io.sleep(.fromSeconds(5), .awake) catch {};
        const client = discord.Client.init(allocator, "1393164834329202769", io) catch continue orelse continue;
        discord_client = client;
        discord_connected.store(true, .release);
        setActivity("In Development", "FV-A.0.0.1") catch {};
        return;
    }
}

pub fn deinitLibs() void {
    discord_stop.store(true, .release);
    if (discord_client) |*client| client.deinit();
}

pub fn setActivity(details: []const u8, state: []const u8) !void {
    if (!discord_connected.load(.acquire)) return;
    if (discord_client) |*client| try client.setActivity(details, state);
}
