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
screen_data: [2048]u8,
stdout: *std.Io.Writer,

pub fn init(stdout: *std.Io.Writer) !Screen {
    const init_flags = sdl3.InitFlags{ .video = true };
    try sdl3.init(init_flags);

    const window = try sdl3.video.Window.init("Chip8", screen_width, screen_height, .{});

    const fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .limited = fps } };

    var data: [2048]u8 = undefined;
    @memset(&data, 0);

    return .{ .init_flags = init_flags, .window = window, .fps_capper = fps_capper, .screen_data = data, .stdout = stdout };
}

pub fn draw(self: *Screen, x: usize, y: usize, sprite_data: []u8) !void {
    var local_y = y;
    for (sprite_data) |sprite| {
        var local_x = x;

        for (0..8) |sprite_index| {
            const sprite_shift: u3 = @intCast(7 - sprite_index);
            const sprite_pixel = (sprite >> sprite_shift) & 1;

            const screen_index = (local_y % 32) * 64 + (local_x % 64);
            var screen_pixel = self.screen_data[screen_index];

            if (sprite_pixel == 1) {
                if (screen_pixel == 1) {
                    screen_pixel = 0;
                } else {
                    screen_pixel = 1;
                }
            }

            self.screen_data[screen_index] = screen_pixel;

            local_x += 1; // next pixel
        }

        local_y += 1; // nex row
    }
}

pub fn clean(self: *Screen) !void {
    @memset(&self.screen_data, 0);
    const color = sdl3.pixels.FColor{ .r = 0, .g = 0, .b = 0, .a = 0 };
    const surface = try self.window.getSurface();
    try surface.clear(color);
}

pub fn flush(self: *Screen) !void {
    const surface = try self.window.getSurface();

    const off_color = surface.mapRgb(0, 0, 0);
    const on_color = surface.mapRgb(255, 255, 255);

    for (self.screen_data, 0..) |pixel, i| {
        const y = i / 64;
        const x = i % 64;
        const rect = sdl3.rect.Rect(i32){
            .x = @intCast(x * scale), //
            .y = @intCast(y * scale), //
            .w = @intCast(1 * scale), // 1 because is a pixel
            .h = @intCast(1 * scale), // scale just to scale, lol
        };

        const color = if (pixel == 1) on_color else off_color;

        try surface.fillRect(rect, color);
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
