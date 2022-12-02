const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const u = @import("../utils.zig");

const Game = @import("../Game.zig");
const enemy = @import("enemy.zig");

pub const Drawable = struct {
    const Self = @This();

    draw_fn: *const fn (iface: *Self, game: *Game) void,
    get_y_fn: *const fn (iface: *const Self) f64,

    pub fn draw(iface: *Self, game: *Game) void {
        iface.draw_fn(iface, game);
    }

    pub fn getY(iface: *const Self) f64 {
        return iface.get_y_fn(iface);
    }
};

const DrawableIter = u.ConcatIterator(
    *Drawable,
    struct {
        @"0": u.SliceIterator(*Drawable),
        @"1": u.InterfaceIterator(u.ObjectPoolIterator(enemy.Guard), "drawable", Drawable),
    },
);

var drawables: std.ArrayList(*Drawable) = undefined;
var initd: bool = false;
pub fn getDrawables(game: *Game) []*Drawable {
    if (!initd) {
        drawables = std.ArrayList(*Drawable).init(game.allocator);
        initd = true;
    }

    drawables.clearRetainingCapacity();

    const singles = [_]*Drawable{
        &game.player.drawable,
    };

    var iter = DrawableIter.init(.{
        u.SliceIterator(*Drawable).init(singles[0..]),
        u.InterfaceIterator(u.ObjectPoolIterator(enemy.Guard), "drawable", Drawable).init(game.enemies.guards.iter()),
    });
    while (iter.iterator.next()) |drawable| {
        drawables.append(drawable) catch unreachable;
    }

    std.sort.sort(*Drawable, drawables.items, {}, cmp);
    return drawables.items;
}

fn cmp(_: void, lhs: *Drawable, rhs: *Drawable) bool {
    return lhs.getY() < rhs.getY();
}
