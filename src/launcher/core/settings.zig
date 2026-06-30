// Write a settings.cfg (Done)
// Windows projects : Stored in Documents/Projects by default (Done)
// Linux projects : Stored in Documents/Projects by default (On test)
// Possibility to change the projects folder and save it
// Settings will also have other things like the shader rebuild for the engine/projects if anything is corrupted
// Maybe a project repair too
//
const std = @import("std");
const mem = std.mem;
const builtin = @import("builtin");

pub const Settings = struct {
    var buffer: [4096]u8 = undefined;

    pub fn settingsInit(io: std.Io, allocator: std.mem.Allocator, environ: *std.process.Environ.Map) !void {
        var createConfigFile = std.Io.Dir.createFile(std.Io.Dir.cwd(), io, "settings.cfg", .{ .read = true, .exclusive = true }) catch |errfile|
            switch (errfile) {
                error.PathAlreadyExists => {
                    return;
                },
                else => return errfile,
            };

        const home = environ.get("HOME") orelse environ.get("USERPROFILE") orelse return error.HomeNotFound;
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

        const home_dir = try std.Io.Dir.cwd().openDir(io, home, .{});
        defer home_dir.close(io);
        const documents_dir = try home_dir.openDir(io, "Documents", .{});
        defer documents_dir.close(io);
        documents_dir.createDir(io, "Singularity Projects", .default_dir) catch |errfolder| switch (errfolder) {
            error.PathAlreadyExists => {
                return;
            },
            else => return errfolder,
        };
    }
};
