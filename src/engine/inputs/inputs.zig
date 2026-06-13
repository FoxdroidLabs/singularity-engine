const std = @import("std");
const glfw = @import("../engine.zig").glfw;

pub const Inputs = struct {
    pub fn isKeyPressed(window: *glfw.Window, key: glfw.Key) bool {
        return window.getKey(key) == .press;
    }
};