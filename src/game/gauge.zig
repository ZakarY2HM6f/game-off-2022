const std = @import("std");

const c = @import("../c.zig");
const u = @import("../utils.zig");
const k = @import("../config.zig");

const Game = @import("../Game.zig");

fn calcSrc(p: f64) c.SDL_Rect {
    return .{
        .x = 26 * @floatToInt(i32, p * 23),
        .y = 0,
        .w = 26,
        .h = 16,
    };
}

pub fn drawBloodGauge(game: *const Game) void {
    const renderer = game.renderer;
    const camera = &game.camera;
    const player = &game.player;

    const src = calcSrc(@intToFloat(f64, player.blood) / k.player_max_blood);
    const dest = c.SDL_Rect{
        .x = @floatToInt(i32, camera.worldToRenderS(k.gauge_offset[0])),
        .y = @floatToInt(i32, camera.worldToRenderS(k.gauge_offset[1])),
        .w = @floatToInt(i32, camera.worldToRenderS(26) * k.ui_sprite_scale),
        .h = @floatToInt(i32, camera.worldToRenderS(16) * k.ui_sprite_scale),
    };

    _ = c.SDL_RenderCopy(renderer, game.textures.get(.gauge), &src, &dest);
}
