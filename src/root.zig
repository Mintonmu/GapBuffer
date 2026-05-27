const std = @import("std");

pub const GapBuffer = struct {
    buffer: []u8,
    capacity: usize,
    gap_start: usize,
    gap_end: usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, capacity: usize) !GapBuffer {
        return GapBuffer{
            .buffer = try allocator.alloc(u8, capacity),
            .capacity = capacity,
            .gap_start = 0,
            .gap_end = capacity,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *GapBuffer) void {
        self.allocator.free(self.buffer);
    }

    pub fn insert(self: *GapBuffer, value: u8) void {
        if (self.gap_start == self.gap_end) {
            self.grow(self.capacity * 2) catch |err| {
                std.debug.print("Error growing gap buffer: {}\n", .{err});
                return;
            };
        }
        self.buffer[self.gap_start] = value;
        self.gap_start += 1;
    }

    pub fn moveCursorLeft(self: *GapBuffer) void {
        if (self.gap_start > 0) {
            self.gap_start -= 1;
            self.gap_end -= 1;
            self.buffer[self.gap_end] = self.buffer[self.gap_start];
        }
    }

    pub fn moveCursorRight(self: *GapBuffer) void {
        if (self.gap_end < self.capacity) {
            self.buffer[self.gap_start] = self.buffer[self.gap_end];
            self.gap_end += 1;
            self.gap_start += 1;
        }
    }

    pub fn backspace(self: *GapBuffer) void {
        if (self.gap_start > 0) {
            self.gap_start -= 1;
        }
    }

    pub fn grow(self: *GapBuffer, new_capacity: usize) !void {
        const new_buffer = try self.allocator.alloc(u8, new_capacity);
        @memcpy(new_buffer[0..self.gap_start], self.buffer[0..self.gap_start]);

        const tail_len = self.capacity - self.gap_end;
        // 计算在 new_buffer 中的新起始位置
        const new_gap_end = new_capacity - tail_len;
        @memcpy(new_buffer[new_gap_end..new_capacity], self.buffer[self.gap_end..self.capacity]);

        self.allocator.free(self.buffer);

        self.buffer = new_buffer;
        self.capacity = new_capacity;
        self.gap_end = new_gap_end;
    }

    // 返回当前 buffer 中的所有有效文本，调用者需要负责 free
    pub fn getText(self: *GapBuffer, allocator: std.mem.Allocator) ![]u8 {
        const text_len = self.gap_start + (self.capacity - self.gap_end);
        const result = try allocator.alloc(u8, text_len);

        @memcpy(result[0..self.gap_start], self.buffer[0..self.gap_start]);
        @memcpy(result[self.gap_start..text_len], self.buffer[self.gap_end..self.capacity]);

        return result;
    }
};

test "GapBuffer: init and basic insert" {
    const gpa = std.testing.allocator;
    var gb = try GapBuffer.init(gpa, 10);
    defer gb.deinit();

    gb.insert('H');
    gb.insert('i');

    const text = try gb.getText(gpa);
    defer gpa.free(text);

    try std.testing.expectEqualStrings("Hi", text);
    try std.testing.expectEqual(@as(usize, 2), gb.gap_start);
}

test "GapBuffer: move cursor left and insert" {
    const gpa = std.testing.allocator;
    var gb = try GapBuffer.init(gpa, 10);
    defer gb.deinit();

    gb.insert('a');
    gb.insert('c');

    // 光标左移一次，现在在 'a' 和 'c' 之间
    gb.moveCursorLeft();
    gb.insert('b');

    const text = try gb.getText(gpa);
    defer gpa.free(text);

    try std.testing.expectEqualStrings("abc", text);
}

test "GapBuffer: move cursor right" {
    const gpa = std.testing.allocator;
    var gb = try GapBuffer.init(gpa, 10);
    defer gb.deinit();

    gb.insert('x');
    gb.insert('y');
    gb.insert('z');

    // 退到最左边
    gb.moveCursorLeft();
    gb.moveCursorLeft();
    gb.moveCursorLeft();

    // 向右移动一步，在 'x' 和 'y' 之间插入
    gb.moveCursorRight();
    gb.insert('-');

    const text = try gb.getText(gpa);
    defer gpa.free(text);

    try std.testing.expectEqualStrings("x-yz", text);
}

test "GapBuffer: backspace" {
    const gpa = std.testing.allocator;
    var gb = try GapBuffer.init(gpa, 10);
    defer gb.deinit();

    gb.insert('H');
    gb.insert('e');
    gb.insert('l');
    gb.insert('x');

    // 删除 'x'
    gb.backspace();
    gb.insert('l');
    gb.insert('o');

    const text = try gb.getText(gpa);
    defer gpa.free(text);

    try std.testing.expectEqualStrings("Hello", text);
}

test "GapBuffer: grow" {
    const gpa = std.testing.allocator;
    // 初始容量只有 2
    var gb = try GapBuffer.init(gpa, 2);
    defer gb.deinit();

    // 插入超过容量的字符，触发 grow
    gb.insert('Z');
    gb.insert('i');
    gb.insert('g');

    const text = try gb.getText(gpa);
    defer gpa.free(text);

    try std.testing.expectEqualStrings("Zig", text);
    // 初始 2，满了后 grow(4)，所以容量应该是 4
    try std.testing.expectEqual(@as(usize, 4), gb.capacity);
}
