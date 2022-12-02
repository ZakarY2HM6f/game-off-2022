const std = @import("std");
const c = @import("c.zig");

pub const debug = false;

pub const name = "Blood & Pain";

pub const window_width = 1280;
pub const window_height = 720;

pub const window_init_width = 1024;
pub const window_init_height = 576;

pub const background_color = .{ 0, 135, 81 };

pub const world_sprite_scale = 5;
pub const ui_sprite_scale = 6;

pub const player_move_speed = 200.0;
pub const player_rotate_speed = 2 * std.math.pi / 0.5;
pub const player_accel_time = 0.2;
pub const player_accel_speed = player_move_speed / player_accel_time;
pub const player_decel_time = 0.1;
pub const player_decel_speed = player_move_speed / player_decel_time;

pub const player_dash_distance = 200.0;
pub const player_dash_time = 0.15;
pub const player_dash_speed = player_dash_distance / player_dash_time;
pub const player_dash_cooldown = 0.7;

pub const player_init_max_heart = 3;
pub const player_init_blood = 0;
pub const player_max_blood = 30;
pub const player_invincibility_time = 0.2;
pub const player_damage_blood = 1;

pub const player_heart2blood_rate = 15;
pub const player_last_breath_time = 1.75;

pub const player_draw_pivot = .{
    32 / 2 * world_sprite_scale,
    15 * world_sprite_scale,
};
pub const player_draw_size = .{ 32, 18 };

pub const player_coll_pivot = .{
    5 * world_sprite_scale,
    15 * world_sprite_scale,
};
pub const player_coll_size = .{
    10 * world_sprite_scale,
    17 * world_sprite_scale,
};

pub const player_scratch_display_time = 0.5;
pub const player_scratch_distance = 12.5 * world_sprite_scale;
pub const player_scratch_radius = 8 * world_sprite_scale;
pub const player_scratch_damage = 12;
pub const player_scratch_curse = 5;
pub const player_scratch_blood_gain = 12;
pub const player_scratch_blood_lose = 2;

pub const player_bullet_offset = .{ 0, -8 * world_sprite_scale };
pub const player_bullet_speed = 420.0;
pub const player_bullet_blood = 2;
pub const player_bullet_damage = 1;
pub const player_bullet_curse = 1.5;
pub const player_bullet_radius = 5;
pub const player_bullet_color = 0xff4d00ff;

pub const bullet_despawn_time = 5;

pub const gauge_offset = .{ 0, 3 * ui_sprite_scale };

pub const heart_offset = .{ 21 * ui_sprite_scale, 5 * ui_sprite_scale };
pub const heart_padding = -2 * ui_sprite_scale;

pub const guard_move_speed = 150.0;
pub const guard_attack_range = 21 * world_sprite_scale;
pub const guard_player_offset = guard_attack_range - 3 * world_sprite_scale;

pub const guard_health = 20;
pub const guard_curse_effect = 2.5;

pub const guard_draw_pivot = .{
    32 / 2 * world_sprite_scale,
    15 * world_sprite_scale,
};
pub const guard_draw_size = .{ 32, 18 };

pub const guard_coll_pivot = .{
    4 * world_sprite_scale,
    15 * world_sprite_scale,
};
pub const guard_coll_size = .{
    8 * world_sprite_scale,
    17 * world_sprite_scale,
};

pub const guard_spear_length = 13 * world_sprite_scale;
pub const guard_spear_offset = .{
    0.5 * world_sprite_scale,
    10 * world_sprite_scale,
};
pub const guard_spear_tip_offset = .{
    0 * world_sprite_scale,
    -3.5 * world_sprite_scale,
};
pub const guard_spear_pivot = .{
    15.5 * world_sprite_scale,
    1.5 * world_sprite_scale,
};

pub const guard_spear_range = guard_attack_range - guard_spear_length;
pub const guard_rotate_speed = std.math.pi * 2 * 0.85;
pub const guard_rotate_curse_effect = 0.1;
pub const guard_thrust_speed = 9.5;
pub const guard_thrust_curse_effect = 0.1;

pub const enemy_corpse_time = 20;
pub const enemy_init_spawn_rate = 7.5;
pub const enemy_min_spawn_rate = 3;
pub const enemy_spawn_accel_rate = 0.1;
pub const enemy_spawn_distance = 800;
