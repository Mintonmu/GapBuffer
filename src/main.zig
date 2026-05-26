const std = @import("std");

const GapBuffer = @import("GapBuffer").GapBuffer;

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    var gap_buffer = try GapBuffer.init(gpa, 1024);
    std.debug.print("gap_buffer: {d}\n", .{gap_buffer.capacity});
    defer gap_buffer.deinit(gpa);
}
