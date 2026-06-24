// extension.zig
// TODO :
// Parse .sproj
// Load project from .sproj
// .sproj :
// [Project]
// name: $project_name
// version: 0.1.0
// engine_version: $engine_version
// entry_scene: main.scene

const std = @import("std");

pub const ExtensionError = error{
    InvalidExtension,
    InvalidFormat,
    MissingSection,
    MissingField,
    UnknownField,
    EmptyValue,
};

pub const extension = struct {
    pub fn parserInit(io: std.Io, gpa: std.mem.Allocator, path: []const u8) !void {
        var found = struct {
            name: bool = true,
            version: bool = true,
            engine_version: bool = true,
            entry_scene: bool = true,
        }{};

        if (!std.mem.endsWith(u8, path, ".sproj")) return error.InvalidExtension;
        var file = try std.Io.Dir.cwd().openFile(io, path, .{});
        defer file.close(io);

        var read_buffer: [1024]u8 = undefined;
        var reader = file.reader(io, &read_buffer);

        var allocating = std.Io.Writer.Allocating.init(gpa);
        defer allocating.deinit();
        _ = try reader.interface.streamRemaining(&allocating.writer);

        const contents = try allocating.toOwnedSlice();
        defer gpa.free(contents);

        var found_section = false;
        var lines = std.mem.splitScalar(u8, contents, '\n');
        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \r");
            if (trimmed.len == 0) continue;
            if (trimmed[0] == '[') {
                if (std.mem.eql(u8, trimmed, "[Project]")) {
                    found_section = true;
                }
                continue;
            }
            var parts = std.mem.splitScalar(u8, trimmed, ':');
            const key = std.mem.trim(u8, parts.first(), " ");
            const value = std.mem.trim(u8, parts.next() orelse continue, " ");

            if (value.len == 0) return error.EmptyValue;

            if (std.mem.eql(u8, key, "name")) {
                found.name = true;
            } else if (std.mem.eql(u8, key, "version")) {
                found.version = true;
            } else if (std.mem.eql(u8, key, "engine_version")) {
                found.engine_version = true;
            } else if (std.mem.eql(u8, key, "entry_scene")) {
                found.entry_scene = true;
            } else {
                return error.UnknownField;
            }

            std.debug.print("key='{s}' value='{s}'\n", .{ key, value });
        }

        if (!found_section) return error.MissingSection;
        if (!found.name or !found.version or !found.engine_version or !found.entry_scene)
            return error.MissingField;
    }
};
