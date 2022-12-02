const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Rand = std.rand.DefaultPrng;

const c = @import("../c.zig");
const u = @import("../utils.zig");
const k = @import("../config.zig");

const Game = @import("../Game.zig");
const Damagable = @import("damagable.zig").Damagable;

pub usingnamespace @import("enemy/guard.zig");
const Guard = @This().Guard;

pub const Enemies = struct {
    const Self = @This();

    guards: u.ObjectPool(Guard),

    random: Rand,
    spawn_rate: f64 = k.enemy_init_spawn_rate,
    spawn_timer: f64 = 0,

    pub fn init(allocator: Allocator) Self {
        const random = Rand.init(0);
        return Self{
            .random = random,
            .guards = u.ObjectPool(Guard).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.guards.deinit();
        self.* = undefined;
    }

    const EnemyIterator = u.ConcatIterator(
        *Damagable,
        struct {
            @"0": u.InterfaceIterator(u.ObjectPoolIterator(Guard), "damagable", Damagable),
        },
    );

    pub fn iter(self: *Self) EnemyIterator {
        return EnemyIterator.init(.{
            u.InterfaceIterator(u.ObjectPoolIterator(Guard), "damagable", Damagable).init(self.guards.iter()),
        });
    }
};

pub fn drawEnemyRects(game: *Game) void {
    const renderer = game.renderer;
    const camera = &game.camera;

    var iter = game.enemies.iter();
    while (iter.iterator.next()) |enemy| {
        const rect = enemy.getRect();
        const x1 = @floatToInt(i16, camera.worldToRenderX(rect.x));
        const y1 = @floatToInt(i16, camera.worldToRenderY(rect.y));
        const x2 = @floatToInt(i16, camera.worldToRenderX(rect.x + rect.w));
        const y2 = @floatToInt(i16, camera.worldToRenderY(rect.y + rect.h));
        _ = c.rectangleColor(renderer, x1, y1, x2, y2, 0xffffffff);
    }
}

pub fn spawnEnemies(game: *Game, delta_time: f64) void {
    const enemies = &game.enemies;

    if (enemies.spawn_timer <= 0) {
        const rotation = enemies.random.random().float(f64) * std.math.pi * 2;
        const direction = u.rotationToVector(rotation);

        enemies.guards.spawn(
            Guard{
                .position = .{
                    direction[0] * k.enemy_spawn_distance,
                    direction[1] * k.enemy_spawn_distance,
                },
            },
        ) catch {};

        enemies.spawn_timer = enemies.spawn_rate;
        enemies.spawn_rate -= k.enemy_spawn_accel_rate;
    }

    enemies.spawn_timer -= delta_time;
}
