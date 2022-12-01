const c = @import("../c.zig");

pub const Texture = enum {
    heart,
    gauge,
    player,
    guard_enemy,

    pub const count = @typeInfo(@This()).Enum.fields.len;

    pub fn path(self: @This()) [*c]const u8 {
        return switch (self) {
            .heart => "res/heart.png",
            .gauge => "res/gauge.png",
            .player => "res/player.png",
            .guard_enemy => "res/guard-enemy.png",
        };
    }
};

pub const Textures = struct {
    const Self = @This();

    textures: [Texture.count]*c.SDL_Texture,

    pub fn init(renderer: *c.SDL_Renderer) !Self {
        var textures: [Texture.count]*c.SDL_Texture = undefined;

        var i: u32 = 0;
        while (i < Texture.count) : (i += 1) {
            const texture = c.IMG_LoadTexture(renderer, @intToEnum(Texture, i).path()) orelse {
                return error.LoadTextureError;
            };
            textures[i] = texture;
        }

        return Self{ .textures = textures };
    }

    pub fn deinit(self: *Self) void {
        for (self.textures) |texture| {
            c.SDL_DestroyTexture(texture);
        }
        self.* = undefined;
    }

    pub fn get(self: *const Self, texture: Texture) *c.SDL_Texture {
        return self.textures[@enumToInt(texture)];
    }
};
