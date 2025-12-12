const std = @import("std");

pub fn main() !void {
    var program_counter: u32 = 0;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const cwd = std.fs.cwd();

    const file = try cwd.openFile("./data/ibm-logo.ch8", .{ .mode = .read_only });
    defer file.close();

    var read_buffer: [1024]u8 = undefined;

    var file_reader: std.fs.File.Reader = .init(file, &read_buffer);
    var reader = &file_reader.interface;

    var buffer: [1024]u8 = undefined;

    @memset(buffer[0..], 0);

    _ = reader.readSliceAll(buffer[0..]) catch 0;

    try stdout.print("{x}\n", .{buffer[0..6]});
    try stdout.flush();
    const pc_increment = 2;
    while (true) {
        // TODO: event driven architecture
        std.Thread.sleep(2000000000);

        const opcode = buffer[program_counter .. program_counter + pc_increment];
        defer program_counter += pc_increment; // the pc_increment may change by the program that is being read

        try stdout.print("{x}\n", .{opcode});

        // const mask: u8 = 0b11110000;
        // const nibble: u8 = (opcode & mask) >> 4;
        // second, third and fourth nibble
        // try stdout.print("nibble: {x}\n", .{nibble});

        // switch (nibble) {
        //     0x0 => {
        //         try stdout.print("instruction: 0\n", .{});
        //     },
        //     else => {},
        // }

        try stdout.flush();
    }
}
