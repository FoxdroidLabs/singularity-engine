// const singularity_engine = @import("singularity_engine");
const std = @import("std");
const core = @import("singularity");
const libs = @import("libs");
const editor = @import("editor");
const engine = @import("engine");
const launcher = @import("launcher");
const extension = @import("launcher/core/extension.zig").extension;
//const vk = @import("vulkan");

fn shouldRunLauncher(init: std.process.Init) !bool {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "launcher") or std.mem.eql(u8, arg, "--launcher")) return true;
    }
    return false;
}

pub fn main(init: std.process.Init) !void {
    const title =
        \\
        \\  +----------------------------------+
        \\  |        SINGULARITY ENGINE        |
        \\  |        ------------------        |
        \\  |        Version: FV-A.0.1         |
        \\  +----------------------------------+
        \\
    ;
    std.debug.print("{s}\n", .{title});

    const render_context = try init.gpa.create(core.VulkanRenderContext);
    defer init.gpa.destroy(render_context);
    try render_context.init(init.gpa);
    defer render_context.deinit(init.gpa);

    if (try shouldRunLauncher(init)) {
        const launcher_app = try init.gpa.create(launcher.Launcher);
        defer init.gpa.destroy(launcher_app);
        extension.parserInit(init.io, init.gpa, "test.sproj") catch |err| {
            std.log.err("Failed to parse .sproj: {}", .{err});
        };
        try launcher_app.init(init.io, init.gpa, render_context);
        defer launcher_app.deinit(render_context);
        try launcher_app.run(init.io, init.gpa, render_context);
        return;
    }

    const coreInit = try init.gpa.create(core.Core);
    defer init.gpa.destroy(coreInit);
    try coreInit.init(init.io, init.gpa, render_context);
    defer coreInit.deinit(render_context);

    try libs.initLibs(init.gpa, init.io);
    defer libs.deinitLibs();
    // editor.initEditor();
    try engine.system.initSystem(init.io, render_context.window.handle, coreInit, render_context, init.gpa);
    //try init.io.sleep(.fromNanoseconds(3 * std.time.ns_per_s), .awake);
}
