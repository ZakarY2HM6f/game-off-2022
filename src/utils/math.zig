const std = @import("std");
const c = @import("../c.zig");

pub fn lerp(a: f64, b: f64, t: f64) f64 {
    return a + (b - a) * t;
}

pub fn vectorToRotation(v: [2]f64) f64 {
    const magnitude = @sqrt(v[0] * v[0] + v[1] * v[1]);
    if (magnitude > 0) {
        var angle = std.math.acos(v[0] / magnitude);
        if (v[1] < 0) angle *= -1;
        return angle;
    }
    return 0;
}

pub fn rotationToVector(r: f64) [2]f64 {
    return .{ std.math.cos(r), std.math.sin(r) };
}

pub fn lerpRotation(a: f64, b: f64, t: f64) f64 {
    const pa = @mod(2 * std.math.pi + a, 2 * std.math.pi);
    const pb = @mod(2 * std.math.pi + b, 2 * std.math.pi);
    const pd = @fabs(pa - pb);

    const qa = blk: {
        if (pa < std.math.pi) break :blk pa else break :blk pa - 2 * std.math.pi;
    };
    const qb = blk: {
        if (pb < std.math.pi) break :blk pb else break :blk pb - 2 * std.math.pi;
    };
    const qd = @fabs(qa - qb);

    if (pd < qd) return lerp(pa, pb, t) else return lerp(qa, qb, t);
}

pub fn distance(a: [2]f64, b: [2]f64) f64 {
    const diff_x = a[0] - b[0];
    const diff_y = a[1] - b[1];
    return @sqrt(diff_x * diff_x + diff_y * diff_y);
}

pub fn directionTo(from: [2]f64, to: [2]f64) [2]f64 {
    var direction = .{ to[0] - from[0], to[1] - from[1] };
    const magnitude = @sqrt(direction[0] * direction[0] + direction[1] * direction[1]);
    if (magnitude > 0) {
        direction[0] /= magnitude;
        direction[1] /= magnitude;
    }
    return direction;
}
