const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const c = @import("../../c.zig");
const k = @import("../../config.zig");
const u = @import("../../utils.zig");

const Game = @import("../../Game.zig");

pub const Bullet = struct {
    const Self = @This();

    radius: f64,

    health: u32,
    curse: f64,

    velocity: [2]f64,
    position: [2]f64,

    despawn_timer: f64 = k.bullet_despawn_time,

    pub fn getRect(self: *const Self) c.SDL_FRect {
        return .{
            .x = @floatCast(f32, self.position[0] - self.radius),
            .y = @floatCast(f32, self.position[1] - self.radius),
            .w = @floatCast(f32, self.radius * 2),
            .h = @floatCast(f32, self.radius * 2),
        };
    }
};

pub const Bullets = struct {
    const Self = @This();

    player: u.ObjectPool(Bullet),

    pub fn init(allocator: Allocator) Self {
        return Self{
            .player = u.ObjectPool(Bullet).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.player.deinit();
        self.* = undefined;
    }
};

pub fn drawBullets(game: *Game) void {
    const renderer = game.renderer;
    const camera = &game.camera;

    var iter = game.bullets.player.iter();
    while (iter.iterator.next()) |bullet| {
        const x = @floatToInt(i16, camera.worldToRenderX(bullet.position[0]));
        const y = @floatToInt(i16, camera.worldToRenderY(bullet.position[1]));
        const r = @floatToInt(i16, camera.worldToRenderS(k.player_bullet_radius));
        _ = c.filledCircleColor(renderer, x, y, r, k.player_bullet_color);
    }
}

pub fn bulletMovement(game: *Game, delta_time: f64) void {
    var iter = game.bullets.player.iter();
    while (iter.iterator.next()) |bullet| {
        bullet.position[0] += bullet.velocity[0] * delta_time;
        bullet.position[1] += bullet.velocity[1] * delta_time;
        bullet.despawn_timer -= delta_time;
        if (bullet.despawn_timer <= 0) {
            @fieldParentPtr(u.ObjectPoolItem(Bullet), "object", bullet).disable();
        }
    }
}

pub fn bulletEnemyCollision(game: *Game) void {
    var enemy_iter = game.enemies.iter();
    while (enemy_iter.iterator.next()) |enemy| {
        const enemy_rect = enemy.getRect();

        var bullet_iter = game.bullets.player.iter();
        while (bullet_iter.iterator.next()) |bullet| {
            const bullet_rect = bullet.getRect();
            if (c.SDL_HasIntersectionF(&enemy_rect, &bullet_rect) != 0) {
                enemy.takeDamage(bullet.health, bullet.curse);
                @fieldParentPtr(u.ObjectPoolItem(Bullet), "object", bullet).disable();
            }
        }
    }
}
