const std = @import("std");

const c = @import("../../c.zig");
const u = @import("../../utils.zig");
const k = @import("../../config.zig");

const Game = @import("../../Game.zig");
const Damagable = @import("../damagable.zig").Damagable;
const Drawable = @import("../drawable.zig").Drawable;

const Sprite = enum(u32) {
    normal,
    dead,
    spear,
};

const sprites = [_]c.SDL_Rect{
    .{
        .x = 0,
        .y = 0,
        .w = k.guard_draw_size[0],
        .h = k.guard_draw_size[1],
    },
    .{
        .x = 32,
        .y = 0,
        .w = k.guard_draw_size[0],
        .h = k.guard_draw_size[1],
    },
    .{
        .x = 64,
        .y = 0,
        .w = k.guard_draw_size[0],
        .h = k.guard_draw_size[1],
    },
};

pub const Guard = struct {
    const Self = @This();

    drawable: Drawable = .{
        .draw_fn = draw,
        .get_y_fn = getY,
    },
    damagable: Damagable = .{
        .get_rect_fn = getRect,
        .take_damage_fn = takeDamage,
    },

    health: u32 = k.guard_health,
    curse: f64 = 0,

    corpse_timer: f64 = k.enemy_corpse_time,

    hit_player: bool = false,

    spear_rotation: f64 = 0,

    animation_state: i32 = 0,
    animation: f64 = 0,

    position: [2]f64,

    fn draw(iface: *Drawable, game: *Game) void {
        const renderer = game.renderer;
        const camera = &game.camera;
        const self = @fieldParentPtr(Self, "drawable", iface);

        {
            const src = &sprites[
                @enumToInt(blk: {
                    if (self.health > 0) break :blk Sprite.normal else break :blk Sprite.dead;
                })
            ];
            const dest = c.SDL_Rect{
                .x = @floatToInt(i32, camera.worldToRenderX(self.position[0] - k.guard_draw_pivot[0])),
                .y = @floatToInt(i32, camera.worldToRenderY(self.position[1] - k.guard_draw_pivot[1])),
                .w = @floatToInt(i32, camera.worldToRenderS(k.guard_draw_size[0] * k.world_sprite_scale)),
                .h = @floatToInt(i32, camera.worldToRenderS(k.guard_draw_size[1] * k.world_sprite_scale)),
            };
            _ = c.SDL_RenderCopyEx(renderer, game.textures.get(.guard_enemy), src, &dest, 0, null, c.SDL_FLIP_NONE);
        }
        if (self.health > 0) {
            const direction = u.rotationToVector(self.spear_rotation);

            const src = &sprites[@enumToInt(Sprite.spear)];

            const p = self.getSpearOrigin();
            const animation_offset = .{
                direction[0] * k.guard_spear_range * self.animation,
                direction[1] * k.guard_spear_range * self.animation,
            };
            const dest = c.SDL_Rect{
                .x = @floatToInt(i32, camera.worldToRenderX(p[0] - k.guard_draw_pivot[0] + animation_offset[0])),
                .y = @floatToInt(i32, camera.worldToRenderY(p[1] - k.guard_draw_pivot[1] + animation_offset[1])),
                .w = @floatToInt(i32, camera.worldToRenderS(k.guard_draw_size[0] * k.world_sprite_scale)),
                .h = @floatToInt(i32, camera.worldToRenderS(k.guard_draw_size[1] * k.world_sprite_scale)),
            };
            const rotation = std.math.radiansToDegrees(f64, u.vectorToRotation(direction) - std.math.pi * 0.5);
            const center = c.SDL_Point{
                .x = @floatToInt(i32, camera.worldToRenderS(k.guard_spear_pivot[0])),
                .y = @floatToInt(i32, camera.worldToRenderS(k.guard_spear_pivot[1])),
            };
            _ = c.SDL_RenderCopyEx(renderer, game.textures.get(.guard_enemy), src, &dest, rotation, &center, c.SDL_FLIP_NONE);
        }
    }

    fn getY(iface: *const Drawable) f64 {
        const self = @fieldParentPtr(Self, "drawable", iface);
        return self.position[1];
    }

    fn getRect(iface: *const Damagable) c.SDL_FRect {
        const self = @fieldParentPtr(Self, "damagable", iface);

        if (self.health > 0) {
            return c.SDL_FRect{
                .x = @floatCast(f32, self.position[0] - k.guard_coll_pivot[0]),
                .y = @floatCast(f32, self.position[1] - k.guard_coll_pivot[1]),
                .w = @floatCast(f32, k.guard_coll_size[0]),
                .h = @floatCast(f32, k.guard_coll_size[1]),
            };
        } else {
            return c.SDL_FRect{ .x = 0, .y = 0, .w = 0, .h = 0 };
        }
    }

    fn takeDamage(iface: *Damagable, health: u32, curse: f64) void {
        const self = @fieldParentPtr(Self, "damagable", iface);
        self.curse += curse;
        self.health -|= health;
    }

    fn getSpearOrigin(self: *const Self) [2]f64 {
        return .{
            self.position[0] + k.guard_spear_offset[0],
            self.position[1] + k.guard_spear_offset[1],
        };
    }

    fn getSpearTip(self: *const Self) c.SDL_FPoint {
        const direction = u.rotationToVector(self.spear_rotation);
        return c.SDL_FPoint{
            .x = @floatCast(f32, self.position[0] + k.guard_spear_tip_offset[0] + direction[0] * (k.guard_spear_length + k.guard_spear_range * self.animation)),
            .y = @floatCast(f32, self.position[1] + k.guard_spear_tip_offset[1] + direction[1] * (k.guard_spear_length + k.guard_spear_range * self.animation)),
        };
    }
};

pub fn guardEnemyAI(game: *Game, delta_time: f64) void {
    const player = &game.player;
    const guards = &game.enemies.guards;

    var iter = guards.iter();
    while (iter.iterator.next()) |guard| {
        if (guard.health > 0) {
            var direction: [2]f64 = .{ 0, 0 };
            direction[0] = player.position[0] - guard.position[0];
            direction[1] = player.position[1] - guard.position[1];

            const distance = @sqrt(direction[0] * direction[0] + direction[1] * direction[1]);
            direction[0] /= distance;
            direction[1] /= distance;

            // movement
            if (distance > k.guard_player_offset) {
                const speed = u.getCursedValue(k.guard_move_speed, guard.curse, k.guard_curse_effect);
                guard.position[0] += speed * direction[0] * delta_time;
                guard.position[1] += speed * direction[1] * delta_time;
            }

            // rotation
            const rotation = u.vectorToRotation(direction);
            const rotate_speed = u.getCursedValue(k.guard_rotate_speed, guard.curse, k.guard_rotate_curse_effect);
            guard.spear_rotation = u.lerpRotation(guard.spear_rotation, rotation, rotate_speed * delta_time);

            // animation
            if (distance < k.guard_attack_range) {
                if (guard.animation_state == 0) {
                    guard.animation_state = -1;
                    guard.hit_player = false;
                }
            } else {
                guard.animation_state = 0;
            }
            animation(guard, delta_time);

            // collision
            if (guard.animation > 0) {
                const tip = guard.getSpearTip();
                const player_rect = player.getRect();
                if (c.SDL_PointInFRect(&tip, &player_rect) != 0 and !guard.hit_player) {
                    player.takeDamage();
                    guard.hit_player = true;
                }
            }
        } else {
            guard.corpse_timer -= delta_time;
            if (guard.corpse_timer <= 0) {
                @fieldParentPtr(u.ObjectPoolItem(Guard), "object", guard).disable();
            }
        }
    }
}

fn animation(guard: *Guard, delta_time: f64) void {
    const thrust_speed = u.getCursedValue(k.guard_thrust_speed, guard.curse, k.guard_thrust_curse_effect);
    switch (guard.animation_state) {
        1 => {
            guard.animation = @min(guard.animation + thrust_speed * delta_time, 1);
            if (guard.animation >= 1) {
                guard.animation_state = -1;
                guard.hit_player = false;
            }
        },
        -1 => {
            guard.animation = @max(guard.animation - thrust_speed * delta_time, -1);
            if (guard.animation <= -1) {
                guard.animation_state = 1;
            }
        },
        0 => {
            if (@fabs(guard.animation) > std.math.floatEps(f64)) {
                if (guard.animation > 0) {
                    guard.animation = @max(guard.animation - thrust_speed * delta_time, 0);
                } else {
                    guard.animation = @min(guard.animation + thrust_speed * delta_time, 0);
                }
            }
        },
        else => unreachable,
    }
}
