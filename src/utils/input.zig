const c = @import("../c.zig");

pub const Input = struct {
    keys: [*c]const u8,
    mouse: struct {
        position: [2]f64,
        button: u32,
    },
};

pub fn getInput() Input {
    const keys = c.SDL_GetKeyboardState(null);
    var mpx: i32 = undefined;
    var mpy: i32 = undefined;
    const mb = c.SDL_GetMouseState(&mpx, &mpy);

    return .{
        .keys = keys,
        .mouse = .{
            .position = .{ @intToFloat(f64, mpx), @intToFloat(f64, mpy) },
            .button = mb,
        },
    };
}
