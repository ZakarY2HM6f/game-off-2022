const std = @import("std");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const ArrayList = std.ArrayList;

const c = @import("c.zig");
const k = @import("config.zig");
const u = @import("utils.zig");

pub usingnamespace @import("game/texture.zig");
pub usingnamespace @import("game/camera.zig");
pub usingnamespace @import("game/drawable.zig");
pub usingnamespace @import("game/damagable.zig");
pub usingnamespace @import("game/player.zig");
pub usingnamespace @import("game/ranged.zig");
pub usingnamespace @import("game/enemy.zig");
pub usingnamespace @import("game/gauge.zig");
pub usingnamespace @import("game/heart.zig");

const Self = @This();

running: bool = undefined,

allocator: Allocator,

window: *c.SDL_Window,
renderer: *c.SDL_Renderer,

textures: Self.Textures,

camera: Self.Camera,

player: Self.Player,
enemies: Self.Enemies,
bullets: Self.Bullets,

pub fn init(allocator: Allocator) !Self {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Failed 'SDL_Init'\nError: %s", c.SDL_GetError());
        return error.SDL_InitError;
    }
    if (c.IMG_Init(c.IMG_INIT_PNG) & c.IMG_INIT_PNG == 0) {
        c.SDL_Log("Failed 'IMG_Init'\nError: %s", c.IMG_GetError());
        return error.IMG_InitError;
    }

    const window = c.SDL_CreateWindow(k.name, c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, k.window_init_width, k.window_init_height, c.SDL_WINDOW_RESIZABLE | c.SDL_WINDOW_ALLOW_HIGHDPI) orelse {
        c.SDL_Log("Failed 'SDL_CreateWindow'\nError: %s", c.SDL_GetError());
        return error.SDL_CreateWindowError;
    };
    const renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_ACCELERATED | c.SDL_RENDERER_PRESENTVSYNC) orelse {
        c.SDL_Log("Failed 'SDL_CreateRenderer'\nError: %s", c.SDL_GetError());
        return error.SDL_CreateRendererError;
    };

    const textures = try Self.Textures.init(renderer);

    const camera = Self.Camera.init(window, renderer);

    const player = Self.Player{};
    const enemies = Self.Enemies.init(allocator);
    const bullets = Self.Bullets.init(allocator);

    return Self{
        .running = true,

        .allocator = allocator,

        .window = window,
        .renderer = renderer,

        .textures = textures,

        .camera = camera,

        .player = player,
        .enemies = enemies,
        .bullets = bullets,
    };
}

pub fn deinit(self: *Self) void {
    self.enemies.deinit();
    self.bullets.deinit();

    self.textures.deinit();

    c.SDL_DestroyRenderer(self.renderer);
    c.SDL_DestroyWindow(self.window);

    c.IMG_Quit();
    c.SDL_Quit();

    self.* = undefined;
}

pub fn loop(self: *Self, delta_time: f64) bool {
    {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) self.onEvent(event);
    }

    self.tick(delta_time);
    self.draw();

    return self.running;
}

fn onEvent(self: *Self, event: c.SDL_Event) void {
    switch (event.@"type") {
        c.SDL_QUIT => self.running = false,
        c.SDL_WINDOWEVENT => {
            switch (event.window.event) {
                c.SDL_WINDOWEVENT_SIZE_CHANGED => self.camera.updateSize(self.window, self.renderer),
                else => {},
            }
        },
        else => {},
    }
}

var last_player_alive = true;
fn tick(self: *Self, delta_time: f64) void {
    const input = u.getInput();

    self.spawnEnemies(delta_time);
    self.guardEnemyAI(delta_time);

    if (self.player.alive) {
        self.playerMovement(input, delta_time);
        self.playerDash(input, delta_time);

        self.playerMeleeAttack(input, delta_time);
        self.playerRangedAttack(input);

        self.playerExchangeBlood(input);
        self.playerRegenerateHeart(input);

        self.playerInvincibility(delta_time);
        self.playerLastBreath(delta_time);
    }
    if (!self.player.alive and last_player_alive) {
        self.gameOver();
    }
    last_player_alive = self.player.alive;

    self.bulletMovement(delta_time);

    self.bulletEnemyCollision();
}

fn gameOver(_: *Self) void {
    c.SDL_Log("game over\n");
}

fn draw(self: *Self) void {
    _ = c.SDL_SetRenderDrawColor(self.renderer, k.background_color[0], k.background_color[1], k.background_color[2], 255);
    _ = c.SDL_RenderClear(self.renderer);

    self.drawBullets();

    var iter = self.drawableIter();
    while (iter.iterator.next()) |drawable| {
        drawable.draw(self);
    }

    self.drawScratch();

    self.drawHeartDisplay();
    self.drawBloodGauge();

    if (k.debug) {
        self.drawPlayerRect();
        self.drawEnemyRects();
    }

    c.SDL_RenderPresent(self.renderer);
}
