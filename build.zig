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
            .imports = &.{
                .{ .name = "singularity", .module = mod },
            },
        }),
    });

    if (target.result.os.tag == .windows) {
        exe.root_module.addWin32ResourceFile(.{
            .file = b.path("assets/app.rc"),
        });
    }

    // Zig GLFW lib from zig-gamedev
    const zglfw = b.dependency("zglfw", .{
        .target = target,
        .optimize = optimize,
        .wayland = true,
        .x11 = true,
    });
    exe.root_module.addImport("zglfw", zglfw.module("root"));
    mod.addImport("zglfw", zglfw.module("root"));
    exe.root_module.linkLibrary(zglfw.artifact("glfw"));

    // Vulkan registry from vulkan-zig by Snektron
    const vulkan = b.dependency("vulkan", .{
        .registry = b.path("registry/vk.xml"),
    }).module("vulkan-zig");
    exe.root_module.addImport("vulkan", vulkan);
    mod.addImport("vulkan", vulkan);

    // Import the libs.zig file that will be used to init all internal libs
    const libs = b.addModule("libs", .{
        .root_source_file = b.path("src/libs/libs.zig"),
    });
    exe.root_module.addImport("libs", libs);

    // Import the editor.zig for futur usage
    const editor = b.addModule("editor", .{
        .root_source_file = b.path("src/editor/editor.zig"),
    });
    exe.root_module.addImport("editor", editor);

    // Import the system.zig for futur usage
    const engine = b.addModule("engine", .{
        .root_source_file = b.path("src/engine/system.zig"),
    });

    // Import Modules in all folders
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
