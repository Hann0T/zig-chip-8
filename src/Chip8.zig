const std = @import("std");
const Chip8 = @This();
const fonts = [_][5]u8{
    .{ 0xF0, 0x90, 0x90, 0x90, 0xF0 }, // 0
    .{ 0x20, 0x60, 0x20, 0x20, 0x70 }, // 1
    .{ 0xF0, 0x10, 0xF0, 0x80, 0xF0 }, // 2
    .{ 0xF0, 0x10, 0xF0, 0x10, 0xF0 }, // 3
    .{ 0x90, 0x90, 0xF0, 0x10, 0x10 }, // 4
    .{ 0xF0, 0x80, 0xF0, 0x10, 0xF0 }, // 5
    .{ 0xF0, 0x80, 0xF0, 0x90, 0xF0 }, // 6
    .{ 0xF0, 0x10, 0x20, 0x40, 0x40 }, // 7
    .{ 0xF0, 0x90, 0xF0, 0x90, 0xF0 }, // 8
    .{ 0xF0, 0x90, 0xF0, 0x10, 0xF0 }, // 9
    .{ 0xF0, 0x90, 0xF0, 0x90, 0x90 }, // A
    .{ 0xE0, 0x90, 0xE0, 0x90, 0xE0 }, // B
    .{ 0xF0, 0x80, 0x80, 0x80, 0xF0 }, // C
    .{ 0xE0, 0x90, 0x90, 0x90, 0xE0 }, // D
    .{ 0xF0, 0x80, 0xF0, 0x80, 0xF0 }, // E
    .{ 0xF0, 0x80, 0xF0, 0x80, 0x80 }, // F
};

alloc: std.mem.Allocator,
pc: u16,
I: u16,
V: [16]u8,

ram: [4096]u8,

stack: std.ArrayList(u16),
delay_timer: u8,
sound_timer: u8,

pub fn init(alloc: std.mem.Allocator) Chip8 {
    var ram = [_]u8{0} ** 4096;

    var font_offset: u8 = 0x050;
    for (fonts) |font| {
        @memcpy(ram[font_offset .. font_offset + font.len], &font);
        font_offset += font.len;
    }

    return .{
        .pc = 0x200, // 512
        .I = 0,
        .V = [_]u8{0} ** 16,
        .ram = ram,
        .alloc = alloc,
        .delay_timer = 0,
        .sound_timer = 0,
        .stack = .empty,
    };
}

pub fn deinit(self: *Chip8) void {
    self.stack.deinit(self.alloc);
}

pub fn load_program(self: *Chip8, program: []u8) void {
    @memcpy(self.ram[0x200 .. 0x200 + program.len], program);
}

pub fn get_opcode(self: *Chip8) u16 {
    const opcode = self.ram[self.pc .. self.pc + 2];
    return (@as(u16, opcode[0]) << 8) | @as(u16, opcode[1]);
}

pub fn increment_pc(self: *Chip8) void {
    self.pc += 2;
}

pub fn set_i(self: *Chip8, location: u16) void {
    self.I = location;
}

pub fn get_sprite_data(self: *Chip8, len: usize) []u8 {
    return self.ram[self.I..(self.I + len)];
}

pub fn set_vx(self: *Chip8, x: usize, value: u8) void {
    self.V[x] = value;
}

pub fn get_vx(self: *Chip8, x: usize) u8 {
    return self.V[x];
}

pub fn add_to_vx(self: *Chip8, x: usize, value: u8) void {
    self.V[x] = self.V[x] +% value;
}

pub fn jump_to(self: *Chip8, address: u16) void {
    self.pc = address;
}

pub fn push_stack(self: *Chip8, address: u16) !void {
    try self.stack.append(self.alloc, address);
}

pub fn pop_stack(self: *Chip8) ?u16 {
    return self.stack.pop();
}

pub fn set_delay_timer(self: *Chip8, time: u8) void {
    self.delay_timer = time;
}

pub fn set_sound_timer(self: *Chip8, time: u8) void {
    self.sound_timer = time;
}

pub fn decrement_timer(self: *Chip8) void {
    if (self.delay_timer > 0) {
        self.delay_timer -= 1;
    }

    if (self.sound_timer > 0) {
        self.sound_timer -= 1;
    }
}
