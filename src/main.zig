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
        \\        SINGULARITY ENGINE
        \\        ------------------
        \\             foxdroid
        \\
    ;
    std.debug.print("{s}", .{title});

    var coreInit = try core.Core.init();
    defer coreInit.deinit();

    try libs.initLibs(init.gpa, init.io);
    defer libs.deinitLibs();
    // editor.initEditor();

    try engine.initSystem(init.io, coreInit.window.handle);
    //try init.io.sleep(.fromNanoseconds(3 * std.time.ns_per_s), .awake);
}
