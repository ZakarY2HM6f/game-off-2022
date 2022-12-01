const std = @import("std");

const c = @import("../c.zig");
const k = @import("../config.zig");

const Game = @import("../Game.zig");

pub const Camera = struct {
    const Self = @This();

    offset: [2]f64,
    win2draw_scale: f64,
    ref2real_scale: f64,

    position: [2]f64 = .{ 0, 0 },

    pub fn init(window: *c.SDL_Window, renderer: *c.SDL_Renderer) Self {
        var self = Self{ .offset = .{ 0, 0 }, .win2draw_scale = 0, .ref2real_scale = 0 };
        self.updateSize(window, renderer);
        return self;
    }

    pub fn worldToScreenS(self: *const Self, s: f64) f64 {
        return s * self.ref2real_scale;
    }
    pub fn worldToScreenX(self: *const Self, x: f64) f64 {
        return self.worldToScreenS(x - self.position[0]) - self.offset[0];
    }
    pub fn worldToScreenY(self: *const Self, y: f64) f64 {
        return self.worldToScreenS(y - self.position[1]) - self.offset[1];
    }
    pub fn worldToScreen(self: *const Self, p: [2]f64) [2]f64 {
        return .{ self.worldToScreenX(p[0]), self.worldToScreenY(p[1]) };
    }

    pub fn screenToWorldS(self: *const Self, s: f64) f64 {
        return s / self.ref2real_scale;
    }
    pub fn screenToWorldX(self: *const Self, x: f64) f64 {
        return self.screenToWorldS(x + self.offset[0]) + self.position[0];
    }
    pub fn screenToWorldY(self: *const Self, y: f64) f64 {
        return self.screenToWorldS(y + self.offset[1]) + self.position[1];
    }
    pub fn screenToWorld(self: *const Self, p: [2]f64) [2]f64 {
        return .{ self.screenToWorldX(p[0]), self.screenToWorldY(p[1]) };
    }

    pub fn worldToRenderS(self: *const Self, s: f64) f64 {
        return self.worldToScreenS(s) * self.win2draw_scale;
    }
    pub fn worldToRenderX(self: *const Self, x: f64) f64 {
        return self.worldToScreenX(x) * self.win2draw_scale;
    }
    pub fn worldToRenderY(self: *const Self, y: f64) f64 {
        return self.worldToScreenY(y) * self.win2draw_scale;
    }
    pub fn worldToRender(self: *const Self, p: [2]f64) [2]f64 {
        return .{ self.worldToRenderX(p[0]), self.worldToRenderY(p[1]) };
    }

    pub fn updateSize(self: *Self, window: *c.SDL_Window, renderer: *c.SDL_Renderer) void {
        var phy_x: i32 = undefined;
        var phy_y: i32 = undefined;
        var log_x: i32 = undefined;
        var log_y: i32 = undefined;
        _ = c.SDL_GetRendererOutputSize(renderer, &phy_x, &phy_y);
        _ = c.SDL_GetWindowSize(window, &log_x, &log_y);

        if (k.debug) {
            c.SDL_Log("physical: %dx%d\n", phy_x, phy_y);
            c.SDL_Log("logical: %dx%d\n", log_x, log_y);
        }

        const phy_xf = @intToFloat(f64, phy_x);
        const phy_yf = @intToFloat(f64, phy_y);
        const log_xf = @intToFloat(f64, log_x);
        const log_yf = @intToFloat(f64, log_y);

        self.offset = .{ log_xf / -2, log_yf / -2 };

        const w2ds_x = phy_xf / log_xf;
        const w2ds_y = phy_yf / log_yf;
        std.debug.assert(@fabs(w2ds_x - w2ds_y) <= std.math.floatEps(f64));
        self.win2draw_scale = (w2ds_x + w2ds_y) / 2;

        const r2rs_x = log_xf / k.window_width;
        const r2rs_y = log_yf / k.window_height;
        std.debug.assert(@fabs(r2rs_x - r2rs_y) <= std.math.floatEps(f64));
        self.ref2real_scale = (r2rs_x + r2rs_y) / 2;
    }
};

pub fn cameraFollowPlayer(game: *Game) void {
    const camera = &game.camera;
    const player = &game.player;

    _ = camera;
    _ = player;
}
