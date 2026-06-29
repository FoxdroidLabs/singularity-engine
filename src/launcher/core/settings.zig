// Write a settings.cfg (Done)
// Windows projects : Stored in Documents/Projects by default (On work)
// Linux projects : Stored in Documents/Projects by default (On work)
// Possibility to change the projects folder and save it
// Settings will also have other things like the shader rebuild for the engine/projects if anything is corrupted
// Maybe a project repair too
//
const std = @import("std");
const mem = std.mem;
const builtin = @import("builtin");

pub const Settings = struct {
    const buf_size = 1024 * 4;
    var buffer: [buf_size]u8 = undefined;

    pub fn settingsInit(io: std.Io, allocator: std.mem.Allocator, environ: *std.process.Environ.Map) !void {
        const home = environ.get("HOME") orelse environ.get("USERPROFILE") orelse return error.HomeNotFound;

        var createConfigFile = std.Io.Dir.createFile(std.Io.Dir.cwd(), io, "settings.cfg", .{ .read = true, .exclusive = true }) catch |err|
            switch (err) {
                error.PathAlreadyExists => {
                    std.log.err("The Settings File already exist", .{});
                    return;
                },
                else => return err,
            };

        const docs_path = try std.fs.path.join(allocator, &[_][]const u8{ home, "Documents", "Singularity Projects" });
        defer allocator.free(docs_path);
        const projects_path = try std.fmt.allocPrint(allocator, "projects_path: {s}", .{docs_path});
        defer allocator.free(projects_path);
        var FirstWriteConfigFile = createConfigFile.writer(io, &buffer);
        try FirstWriteConfigFile.end();
        try FirstWriteConfigFile.interface.writeAll(projects_path);
        try FirstWriteConfigFile.interface.flush();

        try FirstWriteConfigFile.seekTo(0);

        defer createConfigFile.close(io);
    }
};
