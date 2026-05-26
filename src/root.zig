const std = @import("std");

pub const GapBuffer = struct {
    buffer: []u8,
    capacity: usize,
    gap_start: usize,
    gap_end: usize,

    pub fn init(allocator: std.mem.Allocator, capacity: usize) !GapBuffer {
        return GapBuffer{
            .buffer = try allocator.alloc(u8, capacity),
            .capacity = capacity,
            .gap_start = 0,
            .gap_end = 0,
        };
    }

    pub fn deinit(self: GapBuffer, allocator: std.mem.Allocator) void {
        allocator.free(self.buffer);
    }

    pub fn grow() !void {}
};

test "test_gap_buffer" {
    const gpa = std.testing.allocator;
    var gap_buffer = try GapBuffer.init(gpa, 1024);
    defer gap_buffer.deinit(gpa);
    std.debug.print("gap_buffer: {d}\n", .{gap_buffer.capacity});
}
