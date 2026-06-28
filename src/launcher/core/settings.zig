// Write a settings.cfg (Done)
// Windows projects : Stored in Documents/Projects by default (On work)
// Linux projects : Stored in Documents/Projects by default (On work)
// Possibility to change the projects folder and save it
// Settings will also have other things like the shader rebuild for the engine/projects if anything is corrupted
// Maybe a project repair too
//
const std = @import("std");
const mem = std.mem;

pub const Settings = struct {
    const buf_size = 1024 * 4;
    var buffer: [buf_size]u8 = undefined;

    pub fn settingsInit(io: std.Io) !void {
        var createConfigFile = std.Io.Dir.createFile(std.Io.Dir.cwd(), io, "settings.cfg", .{ .read = true, .exclusive = true }) catch |err|
            switch (err) {
                error.PathAlreadyExists => {
                    std.log.err("The Settings File already exist", .{});
                    return;
                },
                else => return err,
            };
        var FirstWriteConfigFile = createConfigFile.writer(io, &buffer);
        try FirstWriteConfigFile.end();
        try FirstWriteConfigFile.interface.writeAll("projects_path: \"$home/Documents/Singularity Project\"");
        try FirstWriteConfigFile.interface.flush();

        try FirstWriteConfigFile.seekTo(0);

        defer createConfigFile.close(io);
    }
};