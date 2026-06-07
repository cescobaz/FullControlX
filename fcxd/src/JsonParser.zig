const std = @import("std");
const Allocator = std.mem.Allocator;

/// Incremental parser for a stream of NUL-delimited top-level JSON values,
/// e.g. `[42, "mouse_move", 100, 200]\0{"x":1}\0` arriving in arbitrary
/// chunks. Each value is terminated by a `\0` byte.
///
/// The parser owns only its internal byte buffer (freed by deinit()). Parsed
/// results are allocated from the allocator you pass to parse(); give it an
/// arena and free every result at once with a single arena.deinit():
///
///   var p = JsonParser.init(gpa);
///   defer p.deinit();
///   var arena = std.heap.ArenaAllocator.init(gpa);
///   defer arena.deinit();
///   for (try p.parse(arena.allocator(), chunk)) |value| {
///       // use `value` ... no per-call cleanup; arena.deinit() frees it all
///   }
const JsonParser = @This();

allocator: Allocator,
buffer: std.ArrayList(u8) = .empty,
/// Buffer offset already scanned for a terminator; lets each call resume
/// the `\0` search instead of restarting from the front.
scan_pos: usize = 0,

pub const terminator: u8 = 0;

pub const Error = std.json.ParseError(std.json.Scanner) || Allocator.Error;

pub fn init(allocator: Allocator) JsonParser {
    return .{ .allocator = allocator };
}

pub fn deinit(self: *JsonParser) void {
    self.buffer.deinit(self.allocator);
}

/// Append `data` and extract every complete (NUL-terminated) JSON value now in
/// the buffer. Returns a slice with one entry per value (empty if no terminator
/// has arrived yet); leftover bytes stay buffered for the next call. Errors on
/// malformed JSON.
///
/// The slice and its values are allocated from `result_allocator` (use an
/// arena you free in bulk). All strings are duped into it, so results stay
/// valid after later parse() calls shift the internal buffer.
pub fn parse(self: *JsonParser, result_allocator: Allocator, data: []const u8) Error![]std.json.Value {
    try self.buffer.appendSlice(self.allocator, data);

    var out: std.ArrayList(std.json.Value) = .empty;
    errdefer out.deinit(result_allocator);
    while (try self.takeOne(result_allocator)) |value| {
        try out.append(result_allocator, value);
    }
    return out.toOwnedSlice(result_allocator);
}

/// Pull the next complete value out of the buffer, or null if the buffer holds
/// no full (NUL-terminated) value yet.
fn takeOne(self: *JsonParser, result_allocator: Allocator) Error!?std.json.Value {
    // Look for the terminator from where we last stopped.
    const term = std.mem.indexOfScalarPos(u8, self.buffer.items, self.scan_pos, terminator) orelse {
        self.scan_pos = self.buffer.items.len; // nothing new to rescan next time
        return null;
    };

    const slice = self.buffer.items[0..term]; // excludes the '\0'
    const value = try std.json.parseFromSliceLeaky(std.json.Value, result_allocator, slice, .{
        .allocate = .alloc_always, // dupe strings; don't alias the buffer we shift below
    });

    // Consume the value and its terminator; keep the tail for next time.
    const consumed = term + 1;
    const remaining = self.buffer.items.len - consumed;
    std.mem.copyForwards(u8, self.buffer.items[0..remaining], self.buffer.items[consumed..]);
    self.buffer.shrinkRetainingCapacity(remaining);
    self.scan_pos = 0;

    return value;
}

test "single complete value" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var p = JsonParser.init(std.testing.allocator);
    defer p.deinit();
    const vals = try p.parse(arena.allocator(), "[1, 2]\x00");
    try std.testing.expectEqual(@as(usize, 1), vals.len);
    try std.testing.expectEqual(@as(usize, 2), vals[0].array.items.len);
    try std.testing.expectEqual(@as(usize, 0), (try p.parse(arena.allocator(), "")).len);
}

test "two terminated values in one chunk" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var p = JsonParser.init(std.testing.allocator);
    defer p.deinit();
    const vals = try p.parse(alloc, "[42, \"mouse_move\", 100, 200]\x00[43, \"mouse_move\", 42, 32]\x00");
    try std.testing.expectEqual(@as(usize, 2), vals.len);
    try std.testing.expectEqual(@as(i64, 42), vals[0].array.items[0].integer);
    try std.testing.expectEqualStrings("mouse_move", vals[1].array.items[1].string);
    // first result still valid after the second was extracted (buffer shifted)
    try std.testing.expectEqualStrings("mouse_move", vals[0].array.items[1].string);
}

test "non-array values parse fine" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var p = JsonParser.init(std.testing.allocator);
    defer p.deinit();
    const vals = try p.parse(arena.allocator(), "{\"k\":1}\x00");
    try std.testing.expectEqual(@as(usize, 1), vals.len);
    try std.testing.expectEqual(@as(i64, 1), vals[0].object.get("k").?.integer);
}

test "partial input returns empty then completes" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var p = JsonParser.init(std.testing.allocator);
    defer p.deinit();
    try std.testing.expectEqual(@as(usize, 0), (try p.parse(alloc, "[1, ")).len);
    try std.testing.expectEqual(@as(usize, 0), (try p.parse(alloc, "2]")).len); // no terminator yet
    const vals = try p.parse(alloc, "\x00");
    try std.testing.expectEqual(@as(usize, 1), vals.len);
    try std.testing.expectEqual(@as(usize, 2), vals[0].array.items.len);
}

test "brackets inside strings ignored" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var p = JsonParser.init(std.testing.allocator);
    defer p.deinit();
    const vals = try p.parse(arena.allocator(), "[\"a]b\"]\x00");
    try std.testing.expectEqualStrings("a]b", vals[0].array.items[0].string);
}

test "malformed json is an error" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var p = JsonParser.init(std.testing.allocator);
    defer p.deinit();
    try std.testing.expectError(error.SyntaxError, p.parse(arena.allocator(), "[1 2]\x00"));
}
