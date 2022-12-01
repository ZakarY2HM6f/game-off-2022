const std = @import("std");

const c = @import("c.zig");

const Game = @import("Game.zig");
var game: Game = undefined;

var count_per_sec: u64 = undefined;
var curr_count: u64 = undefined;
var last_count: u64 = 0;

fn loop() callconv(.C) void {
    const delta_time = blk: {
        last_count = curr_count;
        curr_count = c.SDL_GetPerformanceCounter();
        const delta_count = curr_count - last_count;
        break :blk @intToFloat(f64, delta_count) / @intToFloat(f64, count_per_sec);
    };

    if (!game.running) {
        game = Game.init(std.heap.c_allocator) catch unreachable;
    }
    if (!game.loop(delta_time)) {
        game.deinit();
        c.emscripten_cancel_main_loop();
    }
}

export fn main() callconv(.C) void {
    count_per_sec = c.SDL_GetPerformanceFrequency();
    curr_count = c.SDL_GetPerformanceCounter();

    game.running = false;
    c.emscripten_set_main_loop(loop, 0, 0);
}
