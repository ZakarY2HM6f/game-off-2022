const c = @import("../c.zig");

pub fn calcScreenRect(window_width: i32, window_height: i32, screen_width: i32, screen_height: i32) c.SDL_Rect {
    const window_ratio = @intToFloat(f32, window_width) / @intToFloat(f32, window_height);
    const screen_ratio = @intToFloat(f32, screen_width) / @intToFloat(f32, screen_height);

    var w: i32 = undefined;
    var h: i32 = undefined;

    if (window_ratio > screen_ratio) {
        w = @divTrunc(screen_width * window_height, screen_height);
        h = window_height;
    } else {
        w = window_width;
        h = @divTrunc(screen_height * window_width, screen_height);
    }

    w = @divTrunc(w, screen_width) * screen_width;
    h = @divTrunc(h, screen_height) * screen_height;

    const x = @divTrunc(window_width - w, 2);
    const y = @divTrunc(window_height - h, 2);

    return .{ .x = x, .y = y, .w = w, .h = h };
}
