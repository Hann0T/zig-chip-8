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

pub fn init() !Screen {
    const init_flags = sdl3.InitFlags{ .video = true };
    try sdl3.init(init_flags);

    const window = try sdl3.video.Window.init("Hello SDL3", screen_width, screen_height, .{});

    const fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .limited = fps } };

    return .{ .init_flags = init_flags, .window = window, .fps_capper = fps_capper };
}

pub fn draw(self: *Screen, x: i32, y: i32, height: ?i32) !void {
    const local_h: i32 = (height orelse 1) * scale;

    const rect = sdl3.rect.Rect(i32){ .x = x * scale, .y = y * scale, .w = 8 * scale, .h = local_h };
    const surface = try self.window.getSurface();
    try surface.fillRect(rect, surface.mapRgb(255, 255, 255));
}

pub fn clean(self: *Screen) !void {
    const color = sdl3.pixels.FColor{ .r = 0, .g = 0, .b = 0, .a = 0 };
    const surface = try self.window.getSurface();
    try surface.clear(color);
}

pub fn flush(self: *Screen) !void {
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
