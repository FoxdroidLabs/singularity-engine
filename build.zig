const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseFast,
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
            .strip = true,
            .imports = &.{
                .{ .name = "singularity", .module = mod },
            },
        }),
    });

    const mkdir = b.addSystemCommand(switch (b.graph.host.result.os.tag) {
        .windows => &.{ "cmd", "/c", "if not exist zig-out\\shaders mkdir zig-out\\shaders" },
        else => &.{ "mkdir", "-p", "zig-out/shaders" },
    });
    
    exe.step.dependOn(&mkdir.step);
    const shader_src_dir = "src/core/vulkan/shaders";
    const cwd = std.Io.Dir.cwd();
    var shader_dir = cwd.openDir(b.graph.io, shader_src_dir, .{ .iterate = true }) catch @panic("Cannot open shader dir");
    defer shader_dir.close(b.graph.io);
    var it = shader_dir.iterate();
    while (it.next(b.graph.io) catch @panic("Shader iterator error")) |entry| {
        if (entry.kind != .file) continue;
        const ext = std.fs.path.extension(entry.name);
        if (!std.mem.eql(u8, ext, ".vert") and
            !std.mem.eql(u8, ext, ".frag") and
            !std.mem.eql(u8, ext, ".comp")) continue;
        const sep = std.fs.path.sep_str;
        const src = b.fmt("src{s}core{s}vulkan{s}shaders{s}{s}", .{ sep, sep, sep, sep, entry.name });
        const out = b.fmt("zig-out{s}shaders{s}{s}.spv", .{ sep, sep, entry.name });
        const glslc = b.addSystemCommand(&.{ "glslc", src, "-o", out });
        glslc.step.dependOn(&mkdir.step);
        exe.step.dependOn(&glslc.step);
    }

    if (target.result.os.tag == .windows) {
        exe.root_module.addWin32ResourceFile(.{
            .file = b.path("assets/app.rc"),
        });
    }

    const zglfw = b.dependency("zglfw", .{
        .target = target,
        .optimize = optimize,
        //.import_vulkan = true,
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

    const libs = b.addModule("libs", .{
        .root_source_file = b.path("src/libs/libs.zig"),
    });
    exe.root_module.addImport("libs", libs);

    const editor = b.addModule("editor", .{
        .root_source_file = b.path("src/editor/editor.zig"),
    });
    exe.root_module.addImport("editor", editor);

    const engine = b.addModule("engine", .{
        .root_source_file = b.path("src/engine/system.zig"),
    });

    libs.addImport("zglfw", zglfw.module("root"));
    editor.addImport("zglfw", zglfw.module("root"));
    engine.addImport("zglfw", zglfw.module("root"));

    libs.addImport("vulkan", vulkan);
    editor.addImport("vulkan", vulkan);
    engine.addImport("vulkan", vulkan);

    exe.root_module.addImport("engine", engine);
    b.installArtifact(exe);
    const run_step = b.step("run-engine", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
