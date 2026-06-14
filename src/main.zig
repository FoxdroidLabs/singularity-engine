// const singularity_engine = @import("singularity_engine");
const std = @import("std");
const core = @import("singularity");
const libs = @import("libs");
const editor = @import("editor");
const engine = @import("engine");
//const vk = @import("vulkan");

pub fn main(init: std.process.Init) void {
    run(init) catch |err| {
        std.log.err("Singularity failed to start: {}", .{err});
        switch (err) {
            error.PlatformError => std.log.err("GLFW could not initialize the selected window platform. Try GLFW_PLATFORM=wayland, or check XWayland/Wayland runtime libraries.", .{}),
            error.APIUnavailable => std.log.err("A required API is unavailable. Check Vulkan/GLFW support and installed drivers.", .{}),
            else => {},
        }
        std.process.exit(1);
    };
}

fn run(init: std.process.Init) !void {
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

    const coreInit = try init.gpa.create(core.Core);
    defer init.gpa.destroy(coreInit);
    try coreInit.init(init.io, init.gpa);
    defer coreInit.deinit(init.gpa);

    try libs.initLibs(init.gpa, init.io);
    defer libs.deinitLibs();
    // editor.initEditor();
    try engine.system.initSystem(init.io, coreInit.window.handle, coreInit, init.gpa);
    //try init.io.sleep(.fromNanoseconds(3 * std.time.ns_per_s), .awake);
}
