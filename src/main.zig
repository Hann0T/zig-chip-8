const std = @import("std");
const Chip8 = @import("Chip8.zig");
const Screen = @import("Screen.zig");
const sdl3 = @import("sdl3");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    const page_allocator = std.heap.page_allocator;

    const cwd = std.fs.cwd();

    const file = try cwd.openFile("./data/tests/keypad.ch8", .{ .mode = .read_only });
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

    var screen = try Screen.init(stdout);
    defer screen.deinit();

    var quit = false;

    var key_pad: [16]bool = undefined;
    @memset(&key_pad, false);

    while (!quit) {
        screen.wait();
        // try stdout.print("timer: {d}\n", .{chip8.delay_timer});
        chip8.decrement_timer();

        while (screen.poll_event()) |event|
            switch (event) {
                .quit => quit = true,
                .terminating => quit = true,
                .key_down => {
                    if (event.key_down.key) |key| {
                        switch (key) {
                            .zero => {
                                key_pad[0] = true;
                            },
                            .one => {
                                key_pad[1] = true;
                            },
                            .two => {
                                key_pad[2] = true;
                            },
                            .three => {
                                key_pad[3] = true;
                            },
                            .four => {
                                key_pad[4] = true;
                            },
                            .five => {
                                key_pad[5] = true;
                            },
                            .six => {
                                key_pad[6] = true;
                            },
                            .seven => {
                                key_pad[7] = true;
                            },
                            .eight => {
                                key_pad[8] = true;
                            },
                            .nine => {
                                key_pad[9] = true;
                            },
                            .a => {
                                key_pad[10] = true;
                            },
                            .b => {
                                key_pad[11] = true;
                            },
                            .c => {
                                key_pad[12] = true;
                            },
                            .d => {
                                key_pad[13] = true;
                            },
                            .e => {
                                key_pad[14] = true;
                            },
                            .f => {
                                key_pad[15] = true;
                            },
                            else => {},
                        }
                        break;
                    }
                },
                .key_up => {
                    if (event.key_up.key) |key| {
                        switch (key) {
                            .zero => {
                                key_pad[0] = false;
                            },
                            .one => {
                                key_pad[1] = false;
                            },
                            .two => {
                                key_pad[2] = false;
                            },
                            .three => {
                                key_pad[3] = false;
                            },
                            .four => {
                                key_pad[4] = false;
                            },
                            .five => {
                                key_pad[5] = false;
                            },
                            .six => {
                                key_pad[6] = false;
                            },
                            .seven => {
                                key_pad[7] = false;
                            },
                            .eight => {
                                key_pad[8] = false;
                            },
                            .nine => {
                                key_pad[9] = false;
                            },
                            .a => {
                                key_pad[10] = false;
                            },
                            .b => {
                                key_pad[11] = false;
                            },
                            .c => {
                                key_pad[12] = false;
                            },
                            .d => {
                                key_pad[13] = false;
                            },
                            .e => {
                                key_pad[14] = false;
                            },
                            .f => {
                                key_pad[15] = false;
                            },
                            else => {},
                        }
                        break;
                    }
                },
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
                        chip8.increment_pc();
                    },
                    0x00ee => {
                        try stdout.print("00EE: return to address from stack\n", .{});
                        const address = chip8.pop_stack();
                        if (address) |add| {
                            chip8.jump_to(add);
                        } else {
                            try stdout.print("00EE: stack empty\n", .{});
                            quit = true;
                        }
                    },
                    0x00FD => {
                        try stdout.print("quit program, bye!\n", .{});
                        quit = true;
                    },
                    else => {
                        try stdout.print("TODO: 0x0 something To implement {x}\n", .{opcode_value});
                        std.Thread.sleep(2000000000);
                        quit = true;
                    },
                }
            },
            0x1 => {
                const address: u16 = @intCast(opcode_value & 0x0FFF);
                try stdout.print("jumping to address {x}\n", .{address});

                chip8.jump_to(address);
            },
            0x2 => {
                try stdout.print("0x2NNN {x}\n", .{opcode_value});
                const address: u16 = @intCast(opcode_value & 0x0FFF);
                try chip8.push_stack(chip8.pc + 2); // the next pc
                chip8.jump_to(address);
            },
            0x3 => {
                const x = chip8.get_vx(second_nibble);
                const NN: u8 = @intCast(opcode_value & 0b0000000011111111);
                try stdout.print("is X: {d} == NN: {d}\n", .{ x, NN });
                if (x == NN) {
                    try stdout.print("it is! skipping next code\n", .{});
                    chip8.increment_pc();
                }
                chip8.increment_pc();
            },
            0x4 => {
                const x = chip8.get_vx(second_nibble);
                const NN: u8 = @intCast(opcode_value & 0b0000000011111111);
                try stdout.print("is X: {d} != NN: {d}\n", .{ x, NN });
                if (x != NN) {
                    try stdout.print("it is! skipping next code\n", .{});
                    chip8.increment_pc();
                }
                chip8.increment_pc();
            },
            0x5 => {
                switch (fourth_nibble) {
                    0x0 => {
                        const x = chip8.get_vx(second_nibble);
                        const y = chip8.get_vx(third_nibble);
                        try stdout.print("is X: {d} == Y: {d}\n", .{ x, y });
                        if (x == y) {
                            try stdout.print("it is! skipping next code\n", .{});
                            chip8.increment_pc();
                        }
                        chip8.increment_pc();
                    },
                    else => {
                        try stdout.print("TODO: what is this?: {x}\n", .{opcode_value});
                        quit = true;
                    },
                }
            },
            0x9 => {
                switch (fourth_nibble) {
                    0x0 => {
                        const x = chip8.get_vx(second_nibble);
                        const y = chip8.get_vx(third_nibble);
                        try stdout.print("is X: {d} != Y: {d}\n", .{ x, y });
                        if (x != y) {
                            try stdout.print("it is! skipping next code\n", .{});
                            chip8.increment_pc();
                        }
                        chip8.increment_pc();
                    },
                    else => {
                        try stdout.print("TODO: what is this?: {x}\n", .{opcode_value});
                        quit = true;
                    },
                }
            },
            0x6 => {
                const x: usize = @intCast(second_nibble);
                const value: u8 = @intCast(opcode_value & 0b0000000011111111);
                try stdout.print("setting register V{x} to {x}\n", .{ x, value });

                chip8.set_vx(x, value);
                chip8.increment_pc();
            },
            0x7 => {
                const x: usize = @intCast(second_nibble);
                const value: u8 = @intCast(opcode_value & 0b0000000011111111);
                try stdout.print("adding {x} to V{x}\n", .{ value, x });

                chip8.add_to_vx(x, value);
                chip8.increment_pc();
            },
            0x8 => {
                switch (fourth_nibble) {
                    0x0 => {
                        try stdout.print("8xy0 {x}\n", .{opcode_value});
                        const y = chip8.get_vx(third_nibble);
                        chip8.set_vx(second_nibble, y);
                        chip8.increment_pc();
                    },
                    0x1 => {
                        try stdout.print("8xy1 {x}\n", .{opcode_value});
                        const x = chip8.get_vx(second_nibble);
                        const y = chip8.get_vx(third_nibble);
                        chip8.set_vx(second_nibble, x | y);
                        chip8.increment_pc();
                    },
                    0x2 => {
                        try stdout.print("8xy2 {x}\n", .{opcode_value});
                        const x = chip8.get_vx(second_nibble);
                        const y = chip8.get_vx(third_nibble);
                        chip8.set_vx(second_nibble, x & y);
                        chip8.increment_pc();
                    },
                    0x3 => {
                        try stdout.print("8xy3 {x}\n", .{opcode_value});
                        const x = chip8.get_vx(second_nibble);
                        const y = chip8.get_vx(third_nibble);
                        chip8.set_vx(second_nibble, x ^ y);
                        chip8.increment_pc();
                    },
                    0x4 => {
                        try stdout.print("8xy4 {x}\n", .{opcode_value});
                        const x = chip8.get_vx(second_nibble);
                        const y = chip8.get_vx(third_nibble);
                        const res: u16 = @as(u16, x) + @as(u16, y);

                        chip8.set_vx(second_nibble, @truncate(res));

                        // even if F == X, the flag should overwrite
                        chip8.set_vx(0xF, if (res > 0xFF) 1 else 0);
                        chip8.increment_pc();
                    },
                    0x5 => {
                        try stdout.print("8xy5 {x}\n", .{opcode_value});
                        const x = chip8.get_vx(second_nibble);
                        const y = chip8.get_vx(third_nibble);

                        chip8.set_vx(second_nibble, x -% y);

                        // even if F == X, the flag should overwrite
                        chip8.set_vx(0xF, if (x >= y) 1 else 0);
                        chip8.increment_pc();
                    },
                    0x6 => {
                        try stdout.print("8xy6 {x}\n", .{opcode_value});
                        const y = chip8.get_vx(second_nibble);
                        const flag = y & 1;
                        chip8.set_vx(second_nibble, y >> 1);
                        chip8.set_vx(0xF, flag);

                        chip8.increment_pc();
                    },
                    0x7 => {
                        try stdout.print("8xy7 {x}\n", .{opcode_value});
                        const x = chip8.get_vx(second_nibble);
                        const y = chip8.get_vx(third_nibble);

                        chip8.set_vx(second_nibble, y -% x);

                        // even if F == X, the flag should overwrite
                        chip8.set_vx(0xF, if (y >= x) 1 else 0);
                        chip8.increment_pc();
                    },
                    0xE => {
                        try stdout.print("8xyE {x}\n", .{opcode_value});
                        const y = chip8.get_vx(second_nibble);
                        const flag = (y >> 7) & 1;
                        chip8.set_vx(second_nibble, @truncate(y << 1));
                        chip8.set_vx(0xF, flag);

                        chip8.increment_pc();
                    },
                    else => {
                        try stdout.print("TODO: what is this?: {x}\n", .{opcode_value});
                        quit = true;
                    },
                }
            },
            0xA => {
                try stdout.print("doing the ANNN\n", .{});

                const value = opcode_value & 0b0000111111111111;
                try stdout.print("setting I to {x}\n", .{value});

                chip8.set_i(value);
                chip8.increment_pc();
            },
            0xD => {
                const vX: usize = @intCast(chip8.get_vx(second_nibble));
                const vY: usize = @intCast(chip8.get_vx(third_nibble));
                const len: usize = @intCast(fourth_nibble);
                const sprite_data: []u8 = chip8.get_sprite_data(len);

                try stdout.print("drawing sprite at position X: {d}, Y: {d}\n", .{ vX, vY });

                const collision = try screen.draw(vX, vY, sprite_data);
                try screen.flush();
                chip8.V[0xF] = collision;
                chip8.increment_pc();
            },
            0xE => {
                const second_half: u8 = @truncate(opcode_value);
                switch (second_half) {
                    0xA1 => {
                        const vX = chip8.get_vx(second_nibble);
                        if (!key_pad[vX]) {
                            chip8.increment_pc();
                        }
                        chip8.increment_pc();
                    },
                    0x9E => {
                        const vX = chip8.get_vx(second_nibble);
                        if (key_pad[vX]) {
                            chip8.increment_pc();
                        }
                        chip8.increment_pc();
                    },
                    else => {
                        try stdout.print("TODO: {x}\n", .{opcode_value});
                        quit = true;
                    },
                }
            },
            0xF => {
                const second_half: u8 = @truncate(opcode_value);
                // const second_half: u8 = @intCast(opcode_value & 0b0000000011111111);
                switch (second_half) {
                    0x0A => {
                        try stdout.print("TODO: Fx0A: {x}\n", .{opcode_value});
                        quit = true;
                    },
                    0x1E => {
                        try stdout.print("Fx1E\n", .{});
                        const vX = chip8.get_vx(second_nibble);
                        chip8.set_i(chip8.I + vX);
                        chip8.increment_pc();
                    },
                    0x29 => {
                        try stdout.print("Drawing font Fx29\n", .{});
                        const vX = chip8.get_vx(second_nibble);
                        const index = vX * 5;
                        chip8.set_i(0x050 + index);
                        chip8.increment_pc();
                    },
                    0x33 => {
                        try stdout.print("CALLING Fx33\n", .{});
                        const vX = chip8.get_vx(second_nibble);
                        const I: usize = @intCast(chip8.I);

                        try stdout.print("X: {d}\n", .{vX});
                        try stdout.print("I: {d}\n", .{I});

                        try stdout.print("=====BEFORE=====\n", .{});
                        try stdout.print("I:     {d}\n", .{chip8.ram[I]});
                        try stdout.print("I + 1: {d}\n", .{chip8.ram[I + 1]});
                        try stdout.print("I + 2: {d}\n", .{chip8.ram[I + 2]});

                        chip8.ram[I] = vX / 100;
                        chip8.ram[I + 1] = vX % 100 / 10;
                        chip8.ram[I + 2] = vX % 10;

                        try stdout.print("=====AFTER=====\n", .{});
                        try stdout.print("I:     {d}\n", .{chip8.ram[I]});
                        try stdout.print("I + 1: {d}\n", .{chip8.ram[I + 1]});
                        try stdout.print("I + 2: {d}\n", .{chip8.ram[I + 2]});
                        chip8.increment_pc();
                    },
                    0x55 => {
                        const x = second_nibble;
                        const len = x + 1;
                        @memcpy(chip8.ram[chip8.I..(chip8.I + len)], chip8.V[0..len]);
                        chip8.set_i(chip8.I + len);
                        chip8.increment_pc();
                    },
                    0x65 => {
                        const x = second_nibble;
                        const I: usize = @intCast(chip8.I);

                        // FIX: int overflow
                        for (0..(x + 1)) |vX| {
                            chip8.set_vx(vX, chip8.ram[I + vX]);
                        }

                        chip8.increment_pc();
                    },
                    0x07 => {
                        const timer = chip8.delay_timer;
                        try stdout.print("Fx07: {x} setting vX to: {d}\n", .{ opcode_value, timer });
                        chip8.set_vx(second_nibble, timer);
                        chip8.increment_pc();
                    },
                    0x15 => {
                        const vX = chip8.get_vx(second_nibble);
                        try stdout.print("Fx15: {x} set timer to: {d}\n", .{ opcode_value, vX });
                        chip8.set_delay_timer(vX);
                        chip8.increment_pc();
                    },
                    else => {
                        try stdout.print("TODO: what is this?: {x}\n", .{opcode_value});
                        quit = true;
                        chip8.increment_pc();
                    },
                }
            },
            else => {
                try stdout.print("TODO implement {x}\n", .{opcode_value});
                quit = true;
            },
        }

        try stdout.flush();
    }
}
