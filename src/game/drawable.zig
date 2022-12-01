const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const u = @import("../utils.zig");

const Game = @import("../Game.zig");
const enemy = @import("enemy.zig");

pub const Drawable = struct {
    const Self = @This();

    draw_fn: *const fn (iface: *Self, game: *Game) void,

    pub fn draw(iface: *Self, game: *Game) void {
        iface.draw_fn(iface, game);
    }
};

const DrawableIter = u.ConcatIterator(
    *Drawable,
    struct {
        @"0": u.SliceIterator(*Drawable),
        @"1": u.InterfaceIterator(u.ObjectPoolIterator(enemy.Guard), "drawable", Drawable),
    },
);

pub fn drawableIter(game: *Game) DrawableIter {
    const single_drawables = [_]*Drawable{
        &game.player.drawable,
    };

    return DrawableIter.init(.{
        u.SliceIterator(*Drawable).init(single_drawables[0..]),
        u.InterfaceIterator(u.ObjectPoolIterator(enemy.Guard), "drawable", Drawable).init(game.enemies.guards.iter()),
    });
}
