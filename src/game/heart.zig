const std = @import("std");

const c = @import("../c.zig");
const u = @import("../utils.zig");
const k = @import("../config.zig");

const Game = @import("../Game.zig");

const Sprite = enum(u32) {
    normal,
    broken,
};

const sprites = [_]c.SDL_Rect{
    .{
        .x = 0,
        .y = 0,
        .w = 16,
        .h = 16,
    },
    .{
        .x = 15,
        .y = 0,
        .w = 16,
        .h = 16,
    },
};

pub fn drawHeartDisplay(game: *const Game) void {
    const renderer = game.renderer;
    const camera = &game.camera;
    const player = &game.player;

    const size = @floatToInt(i32, camera.worldToRenderS(16)) * k.ui_sprite_scale;
    const padding = @floatToInt(i32, camera.worldToRenderS(k.heart_padding));

    const x = @floatToInt(i32, camera.worldToRenderS(k.heart_offset[0]));
    const y = @floatToInt(i32, camera.worldToRenderS(k.heart_offset[1]));

    var i: i32 = 0;
    while (i < player.max_heart) : (i += 1) {
        const src = &sprites[
            @enumToInt(blk: {
                if (i < player.heart) break :blk Sprite.normal else break :blk Sprite.broken;
            })
        ];
        const dest = c.SDL_Rect{
            .x = x + i * (size + padding),
            .y = y,
            .w = size, 
            .h = size,
        };
        _ = c.SDL_RenderCopy(renderer, game.textures.get(.heart), src, &dest);
    }
}
