const c = @import("../c.zig");

pub const Damagable = struct {
    const Self = @This();

    get_rect_fn: *const fn (iface: *const Self) c.SDL_FRect,
    take_damage_fn: *const fn (iface: *Self, health: u32, curse: f64) void,

    pub fn getRect(iface: *const Self) c.SDL_FRect {
        return iface.get_rect_fn(iface);
    }

    pub fn takeDamage(iface: *Self, health: u32, curse: f64) void {
        iface.take_damage_fn(iface, health, curse);
    }
};
