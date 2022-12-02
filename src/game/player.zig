const std = @import("std");

const c = @import("../c.zig");
const u = @import("../utils.zig");
const k = @import("../config.zig");

const Game = @import("../Game.zig");
const Bullet = @import("ranged.zig").Bullet;
const Drawable = @import("drawable.zig").Drawable;

const Sprite = enum(u32) {
    normal,
    dead,
    scratch,
};

const sprites = [_]c.SDL_Rect{
    .{
        .x = 0,
        .y = 0,
        .w = k.player_draw_size[0],
        .h = k.player_draw_size[1],
    },
    .{
        .x = 32,
        .y = 0,
        .w = k.player_draw_size[0],
        .h = k.player_draw_size[1],
    },
    .{
        .x = 64,
        .y = 0,
        .w = k.player_draw_size[0],
        .h = k.player_draw_size[1],
    },
};

pub const Player = struct {
    const Self = @This();

    drawable: Drawable = .{
        .draw_fn = draw,
        .get_y_fn = getY,
    },

    max_heart: u32 = k.player_init_max_heart,
    heart: u32 = k.player_init_max_heart,
    invincibility_timer: f64 = 0,

    blood: u32 = k.player_init_blood,
    last_breath_timer: f64 = k.player_last_breath_time,

    scratch_rotation: f64 = 0,
    scratch_position: [2]f64 = .{ 0, 0 },
    scratch_display_timer: f64 = 0,

    alive: bool = true,

    speed: f64 = 0,
    dash_timer: f64 = 0,
    dash_direction: [2]f64 = .{ 0, 0 },

    position: [2]f64 = .{ 0, 0 },
    rotation: f64 = 0,

    pub fn draw(iface: *Drawable, game: *Game) void {
        const renderer = game.renderer;
        const camera = &game.camera;
        const self = @fieldParentPtr(Self, "drawable", iface);

        const src = &sprites[
            @enumToInt(blk: {
                if (self.alive) break :blk Sprite.normal else break :blk Sprite.dead;
            })
        ];
        const dest = c.SDL_Rect{
            .x = @floatToInt(i32, camera.worldToRenderX(self.position[0] - k.player_draw_pivot[0])),
            .y = @floatToInt(i32, camera.worldToRenderY(self.position[1] - k.player_draw_pivot[1])),
            .w = @floatToInt(i32, camera.worldToRenderS(k.player_draw_size[0] * k.world_sprite_scale)),
            .h = @floatToInt(i32, camera.worldToRenderS(k.player_draw_size[1] * k.world_sprite_scale)),
        };
        _ = c.SDL_RenderCopyEx(renderer, game.textures.get(.player), src, &dest, 0, null, c.SDL_FLIP_NONE);
    }

    fn getY(iface: *const Drawable) f64 {
        const self = @fieldParentPtr(Self, "drawable", iface);
        return self.position[1];
    }

    pub fn getRect(self: *const Self) c.SDL_FRect {
        return .{
            .x = @floatCast(f32, self.position[0] - k.player_coll_pivot[0]),
            .y = @floatCast(f32, self.position[1] - k.player_coll_pivot[1]),
            .w = @floatCast(f32, k.player_coll_size[0]),
            .h = @floatCast(f32, k.player_coll_size[1]),
        };
    }

    pub fn takeDamage(self: *Self) void {
        if (self.invincibility_timer <= 0) {
            self.heart -|= 1;
            self.invincibility_timer = k.player_invincibility_time;
            self.blood = @min(self.blood + k.player_damage_blood, k.player_max_blood);
        }
    }
};

pub fn drawScratch(game: *const Game) void {
    const renderer = game.renderer;
    const camera = &game.camera;
    const player = &game.player;

    if (player.heart > 0) {
        if (player.scratch_display_timer > 0) {
            const src = &sprites[@enumToInt(Sprite.scratch)];
            const dest = c.SDL_Rect{
                .x = @floatToInt(i32, camera.worldToRenderX(player.scratch_position[0] - k.player_draw_pivot[0])),
                .y = @floatToInt(i32, camera.worldToRenderY(player.scratch_position[1] - k.player_draw_pivot[1])),
                .w = @floatToInt(i32, camera.worldToRenderS(k.player_draw_size[0] * k.world_sprite_scale)),
                .h = @floatToInt(i32, camera.worldToRenderS(k.player_draw_size[1] * k.world_sprite_scale)),
            };
            _ = c.SDL_RenderCopyEx(renderer, game.textures.get(.player), src, &dest, player.scratch_rotation, null, c.SDL_FLIP_NONE);
        }
    }
}

pub fn drawPlayerRect(game: *const Game) void {
    const renderer = game.renderer;
    const camera = &game.camera;
    const player = &game.player;

    const rect = player.getRect();
    const x1 = @floatToInt(i16, camera.worldToRenderX(rect.x));
    const y1 = @floatToInt(i16, camera.worldToRenderY(rect.y));
    const x2 = @floatToInt(i16, camera.worldToRenderX(rect.x + rect.w));
    const y2 = @floatToInt(i16, camera.worldToRenderY(rect.y + rect.h));
    _ = c.rectangleColor(renderer, x1, y1, x2, y2, 0xffffffff);
}

pub fn playerMovement(game: *Game, input: u.Input, delta_time: f64) void {
    const player = &game.player;

    var movement: [2]f64 = .{ 0, 0 };
    if (input.keys[c.SDL_SCANCODE_W] != 0) {
        movement[1] -= 1;
    }
    if (input.keys[c.SDL_SCANCODE_A] != 0) {
        movement[0] -= 1;
    }
    if (input.keys[c.SDL_SCANCODE_S] != 0) {
        movement[1] += 1;
    }
    if (input.keys[c.SDL_SCANCODE_D] != 0) {
        movement[0] += 1;
    }
    // normalize 'movement'
    if (@fabs(movement[0]) + @fabs(movement[1]) >= 2) {
        const sin45 = 0.7071067811865475;
        movement[0] *= sin45;
        movement[1] *= sin45;
    }

    if (@fabs(movement[0]) + @fabs(movement[1]) > 0) {
        const rotation = u.vectorToRotation(movement);
        player.rotation = u.lerpRotation(player.rotation, rotation, k.player_rotate_speed * delta_time);

        if (player.speed < k.player_move_speed) {
            player.speed += k.player_accel_speed * delta_time;
        } else player.speed = k.player_move_speed;
    } else {
        if (player.speed > 0) {
            player.speed -= k.player_decel_speed * delta_time;
        } else player.speed = 0;
    }

    const direction = .{
        std.math.cos(player.rotation), std.math.sin(player.rotation),
    };

    player.position[0] += direction[0] * player.speed * delta_time;
    player.position[1] += direction[1] * player.speed * delta_time;
}

var last_ks = false;
pub fn playerDash(game: *Game, input: u.Input, delta_time: f64) void {
    const camera = &game.camera;
    const player = &game.player;

    if (player.dash_timer >= -k.player_dash_cooldown) {
        player.dash_timer -= delta_time;
    }

    if (player.dash_timer >= 0) {
        player.position[0] += player.dash_direction[0] * k.player_dash_speed * delta_time;
        player.position[1] += player.dash_direction[1] * k.player_dash_speed * delta_time;
    } else if (input.keys[c.SDL_SCANCODE_SPACE] != 0 and !last_ks) {
        if (player.dash_timer <= -k.player_dash_cooldown) {
            player.dash_direction = u.directionTo(player.position, camera.screenToWorld(input.mouse.position));
            player.dash_timer = k.player_dash_time;
        }
    }
    last_ks = input.keys[c.SDL_SCANCODE_SPACE] != 0;
}

var last_ke = false;
pub fn playerExchangeBlood(game: *Game, input: u.Input) void {
    const player = &game.player;

    if (input.keys[c.SDL_SCANCODE_R] != 0 and !last_ke) {
        if (player.heart > 0 and player.blood < k.player_max_blood) {
            player.heart -= 1;
            player.blood = @min(player.blood + k.player_heart2blood_rate, k.player_max_blood);
        }
    }
    last_ke = input.keys[c.SDL_SCANCODE_R] != 0;
}

var last_kr = false;
pub fn playerRegenerateHeart(game: *Game, input: u.Input) void {
    const player = &game.player;

    if (input.keys[c.SDL_SCANCODE_F] != 0 and !last_kr) {
        if (player.blood >= k.player_heart2blood_rate and player.heart < k.player_init_max_heart) {
            player.heart += 1;
            player.blood -|= k.player_heart2blood_rate;
            player.last_breath_timer = k.player_last_breath_time;
        }
    }
    last_kr = input.keys[c.SDL_SCANCODE_F] != 0;
}

pub fn playerInvincibility(game: *Game, delta_time: f64) void {
    const player = &game.player;

    if (player.invincibility_timer > 0) {
        player.invincibility_timer -= delta_time;
    }
}

pub fn playerLastBreath(game: *Game, delta_time: f64) void {
    const player = &game.player;

    if (player.heart <= 0) {
        player.last_breath_timer -= delta_time;
        if (player.last_breath_timer <= 0) {
            player.alive = false;
        }
    }
}

var last_rb = false;
pub fn playerMeleeAttack(game: *Game, input: u.Input, delta_time: f64) void {
    const camera = &game.camera;
    const player = &game.player;

    if (input.mouse.button & c.SDL_BUTTON_RMASK != 0 and !last_rb) {
        if (player.scratch_display_timer <= 0) {
            player.scratch_display_timer = k.player_scratch_display_time;

            const scratch_direction = u.directionTo(player.position, camera.screenToWorld(input.mouse.position));
            player.scratch_position = .{
                player.position[0] + scratch_direction[0] * k.player_scratch_distance,
                player.position[1] + scratch_direction[1] * k.player_scratch_distance,
            };
            player.scratch_rotation = std.math.radiansToDegrees(f64, u.vectorToRotation(scratch_direction) + std.math.pi);

            const scratch_rect = c.SDL_FRect{
                .x = @floatCast(f32, player.scratch_position[0] - k.player_scratch_radius),
                .y = @floatCast(f32, player.scratch_position[1] - k.player_scratch_radius),
                .w = @floatCast(f32, k.player_scratch_radius * 2),
                .h = @floatCast(f32, k.player_scratch_radius * 2),
            };

            player.blood -|= k.player_scratch_blood_lose;

            var enemy_iter = game.enemies.iter();
            while (enemy_iter.iterator.next()) |enemy| {
                const enemy_rect = enemy.getRect();
                if (c.SDL_HasIntersectionF(&scratch_rect, &enemy_rect) != 0) {
                    enemy.takeDamage(k.player_scratch_damage, k.player_scratch_curse);
                    player.blood = @min(player.blood + k.player_scratch_blood_gain, k.player_max_blood);
                    break;
                }
            }
        }
    }
    last_rb = input.mouse.button & c.SDL_BUTTON_RMASK != 0;

    player.scratch_display_timer -= delta_time;
}

var last_lb = false;
pub fn playerRangedAttack(game: *Game, input: u.Input) void {
    const camera = &game.camera;
    const player = &game.player;

    if (input.mouse.button & c.SDL_BUTTON_LMASK != 0 and !last_lb) {
        if (player.blood >= k.player_bullet_blood) {
            const direction = u.directionTo(player.position, camera.screenToWorld(input.mouse.position));

            game.bullets.player.spawn(
                Bullet{
                    .radius = k.player_bullet_radius,
                    .health = k.player_bullet_damage,
                    .curse = k.player_bullet_curse,
                    .velocity = .{ direction[0] * k.player_bullet_speed, direction[1] * k.player_bullet_speed },
                    .position = .{ player.position[0] + k.player_bullet_offset[0], player.position[1] + k.player_bullet_offset[1] },
                },
            ) catch {};

            player.blood -|= k.player_bullet_blood;
        }
    }
    last_lb = input.mouse.button & c.SDL_BUTTON_LMASK != 0;
}
