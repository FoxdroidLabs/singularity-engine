// const singularity_engine = @import("singularity_engine");
const std = @import("std");
const core = @import("singularity");
const libs = @import("libs");
const editor = @import("editor");
const engine = @import("engine");
//const vk = @import("vulkan");

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

    const coreInit = try init.gpa.create(core.Core);
    defer init.gpa.destroy(coreInit);
    coreInit.* = try core.Core.init(init.io, init.gpa);
    defer coreInit.deinit(init.gpa);

    try libs.initLibs(init.gpa, init.io);
    defer libs.deinitLibs();
    // editor.initEditor();
    try engine.system.initSystem(init.io, coreInit.window.handle, coreInit, init.gpa);
    //try init.io.sleep(.fromNanoseconds(3 * std.time.ns_per_s), .awake);
}
