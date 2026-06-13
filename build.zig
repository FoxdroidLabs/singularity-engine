const std = @import("std");

pub fn build(b: *std.Build) void {
    buildInner(b) catch |err| {
        std.debug.print("Build failed: {}\n", .{err});
        std.process.exit(1);
    };
}

fn buildInner(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .Debug,
    });

    const mod = b.addModule("singularity_engine", .{
        .root_source_file = b.path("src/core/core.zig"),
        .target = target,
    });

    const exe = b.addExecutable(.{
        .name = "singularity",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "singularity", .module = mod },
            },
        }),
    });

    // Shader compilation
    const mkdir = b.addSystemCommand(switch (b.graph.host.result.os.tag) {
        .windows => &.{ "cmd", "/c", "if not exist zig-out\\shaders mkdir zig-out\\shaders" },
        else => &.{ "mkdir", "-p", "zig-out/shaders" },
    });
    exe.step.dependOn(&mkdir.step);

    const naga = switch (b.graph.host.result.os.tag) {
        .windows => "tools\\shader\\naga.exe",
        else => "tools/shader/naga",
    };

    const shader_src_dir = "src/core/vulkan/shaders";
    const cwd = std.Io.Dir.cwd();
    var shader_dir = try cwd.openDir(b.graph.io, shader_src_dir, .{ .iterate = true });
    defer shader_dir.close(b.graph.io);
    var shader_count: usize = 0;
    var it = shader_dir.iterate();
    while (try it.next(b.graph.io)) |entry| {
        if (entry.kind != .file) continue;
        const ext = std.fs.path.extension(entry.name);
        if (!std.mem.eql(u8, ext, ".wgsl")) continue;
        const sep = std.fs.path.sep_str;
        const name = entry.name[0 .. entry.name.len - 5];
        const src = b.fmt("src{s}core{s}vulkan{s}shaders{s}{s}", .{ sep, sep, sep, sep, entry.name });
        const out_vert = b.fmt("zig-out{s}shaders{s}{s}.vert.spv", .{ sep, sep, name });
        const out_frag = b.fmt("zig-out{s}shaders{s}{s}.frag.spv", .{ sep, sep, name });
        const naga_vert = b.addSystemCommand(&.{ naga, "--entry-point", "vs_main", src, out_vert });
        const naga_frag = b.addSystemCommand(&.{ naga, "--entry-point", "fs_main", src, out_frag });
        naga_vert.step.dependOn(&mkdir.step);
        naga_frag.step.dependOn(&mkdir.step);
        exe.step.dependOn(&naga_vert.step);
        exe.step.dependOn(&naga_frag.step);
        shader_count += 1;
    }
    if (shader_count == 0) return error.NoShadersFound;

    const nosubsystem = b.option(bool, "nosubsystem", "Hide console window (Windows only)") orelse false;
    if (nosubsystem) exe.subsystem = .Windows;

    if (target.result.os.tag == .windows) {
        exe.root_module.addWin32ResourceFile(.{
            .file = b.path("assets/app.rc"),
        });
    }

    // Dependencies
    const zglfw = b.dependency("zglfw", .{
        .target = target,
        .optimize = optimize,
        .wayland = true,
        .x11 = true,
    });
    exe.root_module.addImport("zglfw", zglfw.module("root"));
    mod.addImport("zglfw", zglfw.module("root"));
    exe.root_module.linkLibrary(zglfw.artifact("glfw"));

    const vulkan = b.dependency("vulkan", .{
        .registry = b.path("registry/vk.xml"),
    }).module("vulkan-zig");
    exe.root_module.addImport("vulkan", vulkan);
    mod.addImport("vulkan", vulkan);

    // Modules
    const libs = b.addModule("libs", .{
        .root_source_file = b.path("src/libs/libs.zig"),
    });
    const editor = b.addModule("editor", .{
        .root_source_file = b.path("src/editor/editor.zig"),
    });
    const engine = b.addModule("engine", .{
        .root_source_file = b.path("src/engine/engine.zig"),
    });
    engine.addImport("singularity", mod);

    for ([_]*std.Build.Module{ libs, editor, engine }) |m| {
        m.addImport("zglfw", zglfw.module("root"));
        m.addImport("vulkan", vulkan);
    }

    exe.root_module.addImport("libs", libs);
    exe.root_module.addImport("editor", editor);
    exe.root_module.addImport("engine", engine);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    b.step("run-engine", "Run the app").dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run tests");
    for ([_]*std.Build.Module{ mod, exe.root_module }) |m| {
        const t = b.addTest(.{ .root_module = m });
        test_step.dependOn(&b.addRunArtifact(t).step);
    }
}
