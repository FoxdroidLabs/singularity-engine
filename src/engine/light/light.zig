const std = @import("std");

pub const Light = struct {
    position: [3]f32,
    color: [3]f32,
    intensity: f32,
};
