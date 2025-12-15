const sdl3 = @import("sdl3");
const std = @import("std");

const fps = 60;
const scale: i32 = 10;
const screen_width = 64 * scale;
const screen_height = 32 * scale;

const Screen = @This();

init_flags: sdl3.InitFlags,
window: sdl3.video.Window,
fps_capper: sdl3.extras.FramerateCapper(f32),
screen_data: [32][8]u8, // should be [32][8]u8 since u8 is 8pixels and 8*8 is 64
stdout: *std.Io.Writer,

pub fn init(stdout: *std.Io.Writer) !Screen {
    const init_flags = sdl3.InitFlags{ .video = true };
    try sdl3.init(init_flags);

    const window = try sdl3.video.Window.init("Hello SDL3", screen_width, screen_height, .{});

    const fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .limited = fps } };

    var data: [32][8]u8 = undefined;
    @memset(&data, .{0} ** 8);

    return .{ .init_flags = init_flags, .window = window, .fps_capper = fps_capper, .screen_data = data, .stdout = stdout };
}

pub fn draw(self: *Screen, x: usize, y: usize, sprite_data: []u8) !void {
    const screen_x = x / 8;
    const n_shift: u3 = @intCast(x % 8);

    try self.stdout.print("=======================================\n", .{});
    try self.stdout.print("shift: {d}\n", .{n_shift});

    var sprite_rest: u8 = 0;
    var row: usize = 0;
    while (sprite_rest != 0 or row < sprite_data.len) {
        try self.stdout.print("row i: {d}\n", .{row});
        if (row >= sprite_data.len) {
            try self.stdout.print("wtf row?: {d}\n", .{row});
            try self.stdout.print("=======================================\n", .{});
            break;
        }
        const raw_row_sprite = sprite_data[row];
        const screen_y = y + row;
        var sprite = (raw_row_sprite >> n_shift);

        try self.stdout.print("sprite: {b}\n", .{raw_row_sprite});
        try self.stdout.print("right: {b}\n", .{sprite});

        if (sprite_rest != 0) {
            // merge logic
            try self.stdout.print("rest form last draw: {b}\n", .{sprite_rest});
            sprite |= sprite_rest;
            try self.stdout.print("merged: {b}\n", .{sprite});
            sprite_rest = 0; // clean the rest
        } else {
            try self.stdout.print("no rest\n", .{});
        }

        if (raw_row_sprite != 0) {
            const mask: u8 = raw_row_sprite << (7 - n_shift + 1);
            sprite_rest = raw_row_sprite & mask;
            try self.stdout.print("mask: {b}\n", .{mask});
            try self.stdout.print("new rest: {b}\n", .{sprite_rest});
        }

        try self.stdout.print("to draw: {b}\n", .{sprite});

        const screen_col = self.screen_data[screen_y][screen_x];
        const new_screen_col = screen_col ^ sprite;
        self.screen_data[screen_y][screen_x] = new_screen_col;
        try self.stdout.print("=======================================\n", .{});

        if (row < sprite_data.len) row += 1;
    }
}

pub fn clean(self: *Screen) !void {
    @memset(&self.screen_data, .{0} ** 8);
    const color = sdl3.pixels.FColor{ .r = 0, .g = 0, .b = 0, .a = 0 };
    const surface = try self.window.getSurface();
    try surface.clear(color);
}

pub fn flush(self: *Screen) !void {
    const surface = try self.window.getSurface();

    for (self.screen_data, 0..) |row, i| {
        for (row, 0..) |byte, j| {
            for (0..8) |col| {
                const offset: u3 = @intCast(col);
                const pixel = (byte >> (7 - offset)) & 1;

                const rect = sdl3.rect.Rect(i32){
                    .x = @intCast((j * 8 + col) * scale), //
                    .y = @intCast(i * scale), //
                    .w = 1 * scale, // 1 because is a pixel
                    .h = 1 * scale, // scale just to scale, lol
                };

                var color = surface.mapRgb(0, 0, 0);
                if (pixel == 1) {
                    color = surface.mapRgb(255, 255, 255);
                }

                try surface.fillRect(rect, color);
            }
        }
    }

    try self.window.updateSurface();
}

pub fn deinit(self: *Screen) void {
    defer sdl3.shutdown();
    defer sdl3.quit(self.init_flags);
    defer self.window.deinit();
}

pub fn wait(self: *Screen) void {
    const dt = self.fps_capper.delay();
    _ = dt;
}

pub fn poll_event(self: *Screen) ?sdl3.events.Event {
    _ = self;
    return sdl3.events.poll();
}
