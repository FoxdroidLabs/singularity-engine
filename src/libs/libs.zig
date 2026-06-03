const std = @import("std");

pub const discord = @import("discord/discord.zig");

var discord_client: ?discord.Client = null;

pub fn initLibs(allocator: std.mem.Allocator, io: std.Io) !void {
    // std.log.info("Singularity Libs: Libs Init Working", .{});
    discord_client = try discord.Client.init(allocator, "1393164834329202769", io);
    try setActivity("In Development", "FV-A.0.0.1");
}
pub fn deinitLibs() void {
    if (discord_client) |*client| {
        client.deinit();
    }
}

pub fn setActivity(details: []const u8, state: []const u8) !void {
    if (discord_client) |*client| {
        try client.setActivity(details, state);
    }
}
