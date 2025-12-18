const std = @import("std");
const Chip8 = @This();

alloc: std.mem.Allocator,
pc: u16,
I: u16,
V: [16]u8,

ram: [4096]u8,

stack: std.ArrayList(u16),
// delay_timer: u8,
// sound_timer: u8,

pub fn init(alloc: std.mem.Allocator) Chip8 {
    return .{
        .pc = 0x200, // 512
        .I = 0,
        .V = [_]u8{0} ** 16,
        .ram = [_]u8{0} ** 4096,
        .alloc = alloc,
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
    self.V[x] += value;
}

pub fn jump_to(self: *Chip8, address: u16) void {
    self.pc = address;
}
