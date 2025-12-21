const std = @import("std");
const Chip8 = @import("Chip8.zig");
const Screen = @import("Screen.zig");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    const page_allocator = std.heap.page_allocator;

    const cwd = std.fs.cwd();

    const file = try cwd.openFile("./data/test_opcode.ch8", .{ .mode = .read_only });
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
    var skip_next_code = false;

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

        if (skip_next_code) {
            skip_next_code = false;
            chip8.increment_pc();
            continue;
        }

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
            0xF => {
                const second_half: u8 = @truncate(opcode_value);
                // const second_half: u8 = @intCast(opcode_value & 0b0000000011111111);
                switch (second_half) {
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
                    },
                    else => {},
                }
            },
            0x3 => {
                const x = chip8.get_vx(second_nibble);
                const NN: u8 = @intCast(opcode_value & 0b0000000011111111);
                try stdout.print("is X: {d} == NN: {d}\n", .{ x, NN });
                if (x == NN) {
                    try stdout.print("it is! skipping next code\n", .{});
                    skip_next_code = true;
                }
            },
            0x4 => {
                const x = chip8.get_vx(second_nibble);
                const NN: u8 = @intCast(opcode_value & 0b0000000011111111);
                try stdout.print("is X: {d} != NN: {d}\n", .{ x, NN });
                if (x != NN) {
                    try stdout.print("it is! skipping next code\n", .{});
                    skip_next_code = true;
                }
            },
            0x5 => {
                const x = chip8.get_vx(second_nibble);
                const y = chip8.get_vx(third_nibble);
                try stdout.print("is X: {d} == Y: {d}\n", .{ x, y });
                if (x == y) {
                    try stdout.print("it is! skipping next code\n", .{});
                    skip_next_code = true;
                }
            },
            0x9 => {
                const x = chip8.get_vx(second_nibble);
                const y = chip8.get_vx(third_nibble);
                try stdout.print("is X: {d} != Y: {d}\n", .{ x, y });
                if (x != y) {
                    try stdout.print("it is! skipping next code\n", .{});
                    skip_next_code = true;
                }
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
            },
            0x1 => {
                const address: u16 = @intCast(opcode_value & 0x0FFF);
                try stdout.print("jumping to address {x}\n", .{address});
                try stdout.flush();

                chip8.jump_to(address);
                continue;
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
            0x8 => {
                switch (fourth_nibble) {
                    0x0 => {
                        const y = chip8.get_vx(third_nibble);
                        chip8.set_vx(second_nibble, y);
                    },
                    0x1 => {
                        const x = chip8.get_vx(second_nibble);
                        const y = chip8.get_vx(third_nibble);
                        chip8.set_vx(second_nibble, x | y);
                    },
                    0x2 => {
                        const x = chip8.get_vx(second_nibble);
                        const y = chip8.get_vx(third_nibble);
                        chip8.set_vx(second_nibble, x & y);
                    },
                    0x3 => {
                        const x = chip8.get_vx(second_nibble);
                        const y = chip8.get_vx(third_nibble);
                        chip8.set_vx(second_nibble, x ^ y);
                    },
                    0x4 => {
                        const x = chip8.get_vx(second_nibble);
                        const y = chip8.get_vx(third_nibble);
                        const res: u16 = @as(u16, x) + @as(u16, y);

                        chip8.set_vx(second_nibble, @truncate(res));

                        // even if F == X, the flag should overwrite
                        chip8.set_vx(0xF, if (res > 0xFF) 1 else 0);
                    },
                    0x5 => {
                        const x = chip8.get_vx(second_nibble);
                        const y = chip8.get_vx(third_nibble);

                        chip8.set_vx(second_nibble, x -% y);

                        // even if F == X, the flag should overwrite
                        chip8.set_vx(0xF, if (x >= y) 1 else 0);
                    },
                    0x6 => {
                        const y = chip8.get_vx(third_nibble);
                        chip8.set_vx(0xF, y & 1);
                        chip8.set_vx(second_nibble, y >> 1);
                    },
                    0x7 => {
                        const x = chip8.get_vx(second_nibble);
                        const y = chip8.get_vx(third_nibble);

                        chip8.set_vx(second_nibble, y -% x);

                        // even if F == X, the flag should overwrite
                        chip8.set_vx(0xF, if (y >= x) 1 else 0);
                    },
                    0xE => {
                        const y = chip8.get_vx(third_nibble);
                        chip8.set_vx(0xF, (y >> 7) & 1);
                        chip8.set_vx(second_nibble, @truncate(y << 1));
                    },
                    else => {
                        try stdout.print("TODO: what is this?: {x}\n", .{opcode_value});
                    },
                }
            },
            0xA => {
                try stdout.print("doing the ANNN\n", .{});

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
