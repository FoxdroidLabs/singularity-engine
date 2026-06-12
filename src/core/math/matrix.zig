const std = @import("std");
const vec = @import("vector.zig").Vector;

pub const Matrix4 = struct {
    data: [4][4]f32,

    pub fn multiply(a: Matrix4, b: Matrix4) Matrix4 {
        var m_result = std.mem.zeroes(Matrix4);
        for (0..4) |i| {
            for (0..4) |j| {
                for (0..4) |k| {
                    m_result.data[i][j] += a.data[i][k] * b.data[k][j];
                }
            }
        }
        return m_result;
    }

    pub fn identity() Matrix4 {
        var i_result = std.mem.zeroes(Matrix4);
        for (0..4) |i| {
            i_result.data[i][i] = 1.0;
        }
        return i_result;
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
        var t_result = Matrix4.identity();
        t_result.data[3][0] = x;
        t_result.data[3][1] = y;
        t_result.data[3][2] = z;
        return t_result;
    }

    pub fn lookAt(eye: vec, center: vec, up: vec) Matrix4 {
        const f = vec.normalize(vec.sub(center, eye));
        const r = vec.normalize(vec.cross(f, up));
        const u = vec.cross(r, f);
        var l_result = std.mem.zeroes(Matrix4);
        l_result.data[0][0] = r.x;
        l_result.data[0][1] = r.y;
        l_result.data[0][2] = r.z;
        l_result.data[0][3] = -vec.dot(r, eye);
        l_result.data[1][0] = u.x;
        l_result.data[1][1] = u.y;
        l_result.data[1][2] = u.z;
        l_result.data[1][3] = -vec.dot(u, eye);
        l_result.data[2][0] = -f.x;
        l_result.data[2][1] = -f.y;
        l_result.data[2][2] = -f.z;
        l_result.data[2][3] = vec.dot(f, eye);
        l_result.data[3][3] = 1.0;
        return l_result;
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
};
