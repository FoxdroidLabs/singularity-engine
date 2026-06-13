const std = @import("std");
const vec = @import("vector.zig").Vector;

pub const Matrix4 = struct {
    data: [4][4]f32,

    pub fn multiply(a: Matrix4, b: Matrix4) Matrix4 {
        var result = std.mem.zeroes(Matrix4);
        for (0..4) |i| {
            for (0..4) |j| {
                for (0..4) |k| {
                    result.data[i][j] += a.data[i][k] * b.data[k][j];
                }
            }
        }
        return result;
    }

    pub fn identity() Matrix4 {
        var result = std.mem.zeroes(Matrix4);
        for (0..4) |i| {
            result.data[i][i] = 1.0;
        }
        return result;
    }

    pub fn perspective(fov: f32, aspect: f32, near: f32, far: f32) Matrix4 {
        const tan_half_fov = @tan(fov / 2.0);
        var p = std.mem.zeroes(Matrix4);
        p.data[0][0] = 1.0 / (aspect * tan_half_fov);
        p.data[1][1] = -1.0 / tan_half_fov;
        p.data[2][2] = far / (near - far);
        p.data[2][3] = -1.0;
        p.data[3][2] = (near * far) / (near - far);
        return p;
    }

    pub fn translation(x: f32, y: f32, z: f32) Matrix4 {
        var result = Matrix4.identity();
        result.data[3][0] = x;
        result.data[3][1] = y;
        result.data[3][2] = z;
        return result;
    }

    pub fn lookAt(eye: vec, center: vec, up: vec) Matrix4 {
        const f = vec.normalize(vec.sub(center, eye));
        const r = vec.normalize(vec.cross(f, up));
        const u = vec.cross(r, f);
        var result = std.mem.zeroes(Matrix4);
        result.data[0][0] = r.x;
        result.data[1][0] = r.y;
        result.data[2][0] = r.z;
        result.data[3][0] = -vec.dot(r, eye);
        result.data[0][1] = u.x;
        result.data[1][1] = u.y;
        result.data[2][1] = u.z;
        result.data[3][1] = -vec.dot(u, eye);
        result.data[0][2] = -f.x;
        result.data[1][2] = -f.y;
        result.data[2][2] = -f.z;
        result.data[3][2] = vec.dot(f, eye);
        result.data[3][3] = 1.0;
        return result;
    }

    pub fn transpose(m: Matrix4) Matrix4 {
        var result = std.mem.zeroes(Matrix4);
        for (0..4) |i| {
            for (0..4) |j| {
                result.data[i][j] = m.data[j][i];
            }
        }
        return result;
    }

    pub fn rotationY(angle: f32) Matrix4 {
        const c = @cos(angle);
        const s = @sin(angle);
        var result = Matrix4.identity();
        result.data[0][0] = c;
        result.data[2][0] = s;
        result.data[0][2] = -s;
        result.data[2][2] = c;
        return result;
    }
};
