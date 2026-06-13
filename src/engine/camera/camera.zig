const std = @import("std");
const math = @import("singularity").math;
const glfw = @import("../engine.zig").glfw;

pub const Camera = struct {
    pos: math.Vector,
    yaw: f32,
    pitch: f32,
    speed: f32,
    last_x: f64,
    last_y: f64,
    first_mouse: bool,

    pub fn init() Camera {
        return .{ .pos = .{ .x = 1.6, .y = 1.4, .z = 2.6 }, .yaw = -90.0, .pitch = 0.0, .speed = 2.0, .last_x = 0.0, .last_y = 0.0, .first_mouse = true };
    }

    pub fn update(self: *Camera, window: *glfw.Window, dt: f32) void {
        const sensitivity: f32 = 0.1;
        const cursor = window.getCursorPos();
        if (self.first_mouse) {
            self.last_x = cursor[0];
            self.last_y = cursor[1];
            self.first_mouse = false;
        }
        const dx = @as(f32, @floatCast(cursor[0] - self.last_x)) * sensitivity;
        const dy = @as(f32, @floatCast(cursor[1] - self.last_y)) * sensitivity;
        self.last_x = cursor[0];
        self.last_y = cursor[1];
        self.yaw += dx;
        self.pitch += dy;
        if (self.pitch > 89.0) self.pitch = 89.0;
        if (self.pitch < -89.0) self.pitch = -89.0;

        const rad_yaw = std.math.degreesToRadians(self.yaw);
        const rad_pitch = std.math.degreesToRadians(self.pitch);
        const front = math.Vector{
            .x = @cos(rad_yaw) * @cos(rad_pitch),
            .y = @sin(rad_pitch),
            .z = @sin(rad_yaw) * @cos(rad_pitch),
        };
        const f = math.Vector.normalize(front);
        const right = math.Vector.normalize(math.Vector.cross(f, .{ .x = 0.0, .y = 1.0, .z = 0.0 }));
        const spd = self.speed * dt;
        if (window.getKey(.w) == .press) self.pos = math.Vector.add(self.pos, math.Vector.scale(f, spd));
        if (window.getKey(.s) == .press) self.pos = math.Vector.sub(self.pos, math.Vector.scale(f, spd));
        if (window.getKey(.a) == .press) self.pos = math.Vector.sub(self.pos, math.Vector.scale(right, spd));
        if (window.getKey(.d) == .press) self.pos = math.Vector.add(self.pos, math.Vector.scale(right, spd));
        if (window.getKey(.space) == .press) self.pos.y -= spd;
        if (window.getKey(.left_shift) == .press) self.pos.y += spd;
    }

    pub fn getView(self: *Camera) math.Matrix4 {
        const rad_yaw = std.math.degreesToRadians(self.yaw);
        const rad_pitch = std.math.degreesToRadians(self.pitch);
        const front = math.Vector{
            .x = @cos(rad_yaw) * @cos(rad_pitch),
            .y = @sin(rad_pitch),
            .z = @sin(rad_yaw) * @cos(rad_pitch),
        };
        const target = math.Vector.add(self.pos, math.Vector.normalize(front));
        return math.Matrix4.lookAt(self.pos, target, .{ .x = 0.0, .y = 1.0, .z = 0.0 });
    }
};
