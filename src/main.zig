const std = @import("std");
const Chip8 = @import("Chip8.zig");
const Screen = @import("Screen.zig");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    const page_allocator = std.heap.page_allocator;

    const cwd = std.fs.cwd();

    const file = try cwd.openFile("./data/ibm.ch8", .{ .mode = .read_only });
    defer file.close();

    var read_buffer: [1024]u8 = undefined;

    var file_reader: std.fs.File.Reader = .init(file, &read_buffer);
    var reader = &file_reader.interface;

    var buffer: [1024]u8 = undefined;

    @memset(buffer[0..], 0);

    _ = reader.readSliceAll(buffer[0..]) catch 0;

    try stdout.print("buffer sample: {x}\n", .{buffer[0..6]});
    try stdout.print("buffer len: {x}\n", .{buffer.len});
    try stdout.flush();

    var chip8 = Chip8.init(page_allocator);
    defer chip8.deinit();

    chip8.load_program(&buffer);
    // try stdout.print("228: {x}\n", .{chip8.ram[0x200 + 0x228]});
    // try stdout.flush();

    var screen = try Screen.init(stdout);
    defer screen.deinit();

    var quit = false;
    while (!quit) {
        // TODO: event driven architecture
        // std.Thread.sleep(2000000000);
        screen.wait();

        while (screen.poll_event()) |event|
            switch (event) {
                .quit => quit = true,
                .terminating => quit = true,
                else => {},
            };

        const opcode_value = chip8.get_opcode();
        // try stdout.print("opcode value: {x}\n", .{opcode_value});

        const first_nibble: u4 = @intCast((opcode_value & 0b1111000000000000) >> 12);
        const second_nibble: u4 = @intCast((opcode_value & 0b0000111100000000) >> 8);
        const third_nibble: u4 = @intCast((opcode_value & 0b0000000011110000) >> 4);
        const fourth_nibble: u4 = @intCast(opcode_value & 0b0000000000001111);

        switch (first_nibble) {
            0x0 => {
                switch (opcode_value) {
                    0x00e0 => {
                        try stdout.print("clear screen\n", .{});
                        try screen.clean();
                        try screen.flush();
                    },
                    0x00ee => {
                        try stdout.print("return to address from stack\n", .{});
                    },
                    0x00FD => {
                        try stdout.print("quit program, bye!\n", .{});
                        quit = true;
                    },
                    else => {
                        try stdout.print("0x0 something To implement {x}\n", .{opcode_value});
                        std.Thread.sleep(2000000000);
                        quit = true;
                    },
                }
            },
            0xD => {
                const vX: usize = @intCast(chip8.get_vx(second_nibble));
                const vY: usize = @intCast(chip8.get_vx(third_nibble));
                const len: usize = @intCast(fourth_nibble);
                const sprite_data: []u8 = chip8.get_sprite_data(len);
                try stdout.print("draw sprite at position {x}, {x} with sprite data\n", .{ vX, vY });
                // try stdout.print("x: {d}, index: {d}, mod: {d} and y?: {d}\n", .{ vX, vX / 8, vX % 8, vY });
                // try stdout.print("sprite data: {d}\n", .{sprite_data.len});

                // try stdout.print("before: {{\n", .{});
                // for (screen.screen_data) |row| {
                //     try stdout.print("{any},\n", .{row});
                // }
                // try stdout.print("}}\n", .{});

                try screen.draw(vX, vY, sprite_data);

                // try stdout.print("after: {{\n", .{});
                // for (screen.screen_data) |row| {
                //     try stdout.print("{any},\n", .{row});
                // }
                // try stdout.print("}}\n", .{});

                try screen.flush();
                // try stdout.print("draw 8x{x} pixel sprite at position v{x}, v{x} with data starting at the address in I, I is not changed\n", .{ fourth_nibble, second_nibble, third_nibble });
            },
            0x1 => {
                const address: u16 = @intCast(opcode_value & 0x0FFF);
                try stdout.print("jumping to address {x}\n", .{address});
                // try stdout.print("pc before {x}\n", .{chip8.pc});
                chip8.jump_to(address);
                // try stdout.print("pc after {x}\n", .{chip8.pc});
                // continue; // do NOT increment the PC
            },
            0x6 => {
                const x: usize = @intCast(second_nibble);
                const value: u8 = @intCast(opcode_value & 0b0000000011111111);
                try stdout.print("setting register V{x} to {x}\n", .{ x, value });
                chip8.set_vx(x, value);
            },
            0x7 => {
                const x: usize = @intCast(second_nibble);
                const value: u8 = @intCast(opcode_value & 0b0000000011111111);
                try stdout.print("adding {x} to V{x}\n", .{ value, x });
                chip8.add_to_vx(x, value);
            },
            0xA => {
                const value = opcode_value & 0b0000111111111111;
                try stdout.print("setting I to {x}\n", .{value});
                chip8.set_i(value);
            },
            else => {
                try stdout.print("TO implement {x}\n", .{opcode_value});
            },
        }

        try stdout.flush();
        chip8.increment_pc();
    }
}
