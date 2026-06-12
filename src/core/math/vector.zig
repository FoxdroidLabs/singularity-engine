const std = @import("std");

// TODO: normalize, cross

pub const Vector = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn dot(a: Vector, b: Vector) f32 {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }

    pub fn add(a: Vector, b: Vector) Vector {
        return .{
            .x = a.x + b.x,
            .y = a.y + b.y,
            .z = a.z + b.z,
        };
    }

    pub fn sub(a: Vector, b: Vector) Vector {
        return .{
            .x = a.x - b.x,
            .y = a.y - b.y,
            .z = a.z - b.z,
        };
    }

    pub fn scale(self: Vector, s: f32) Vector {
        return .{ .x = self.x * s, .y = self.y * s, .z = self.z * s };
    }

    pub fn lenght(self: Vector) f32 {
        return @sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }

    pub fn normalize(self: Vector) Vector {
        const l = self.lenght();
        return .{ .x = self.x / l, .y = self.y / l, .z = self.z / l };
    }

    pub fn cross(a: Vector, b: Vector) Vector {
        return .{
            .x = a.y * b.z - a.z * b.y,
            .y = a.z * b.x - a.x * b.z,
            .z = a.x * b.y - a.y * b.x,
        };
    } 

    pub fn toArray(self: Vector) [3]f32 {
        return .{ self.x, self.y, self.z };
    }
}; 
