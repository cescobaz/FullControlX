const std = @import("std");

const Request = @This();

id: u32,
payload: Payload,

pub const Error = error{ InvalidRequest, UnknownCommand, InvalidParams };

/// Every command. Used as the tag type of Payload, so the union below is
/// *forced* to define a params struct for each one — add a command here and
/// it won't compile until Payload covers it.
pub const Cmd = enum {
    mouse_move,
    mouse_drag,
    mouse_left_down,
    mouse_left_up,
    mouse_left_click,
    mouse_right_click,
    mouse_double_click,
    mouse_scroll_wheel,
    keyboard_type_text,
    keyboard_type_symbol,
    system_info,
    ui_apps,
    apps_observe,
    ignore_all,
};

const XY = struct { x: i32, y: i32 };
const Text = struct { text: []const u8 };
const Symbol = struct { symbol: []const u8 };
const None = struct {};

/// Typed params per command. `union(Cmd)` means the compiler requires one
/// field for every Cmd value — that's the compile-time completeness check.
pub const Payload = union(Cmd) {
    mouse_move: XY,
    mouse_drag: XY,
    mouse_left_down: None,
    mouse_left_up: None,
    mouse_left_click: None,
    mouse_right_click: None,
    mouse_double_click: None,
    mouse_scroll_wheel: XY,
    keyboard_type_text: Text,
    keyboard_type_symbol: Symbol,
    system_info: None,
    ui_apps: None,
    apps_observe: None,
    ignore_all: None,
};

/// Parse a raw `[id, cmd, ...params]` JSON value into a typed Request: requires
/// an array, pops id (integer) and cmd (string), maps cmd -> enum, then fills
/// the matching params struct from the tail, checking count and element types.
/// `[]const u8` fields alias `value`, so the arena behind it must outlive
/// the result.
pub fn fromJson(value: std.json.Value) Error!Request {
    if (value != .array) return Error.InvalidRequest;
    const array = value.array;

    if (array.items.len < 2) return Error.InvalidRequest;
    const id = switch (array.items[0]) {
        .integer => |n| std.math.cast(u32, n) orelse return Error.InvalidRequest,
        else => return Error.InvalidRequest,
    };
    if (array.items[1] != .string) return Error.InvalidRequest;

    const cmd = std.meta.stringToEnum(Cmd, array.items[1].string) orelse return Error.UnknownCommand;
    const params = array.items[2..];
    const payload: Payload = switch (cmd) {
        inline else => |tag| @unionInit(
            Payload,
            @tagName(tag),
            try parseStruct(@FieldType(Payload, @tagName(tag)), params),
        ),
    };
    return .{ .id = id, .payload = payload };
}

/// Fill struct `T` from the params slice, one field per element in order.
fn parseStruct(comptime T: type, params: []const std.json.Value) Error!T {
    const fields = @typeInfo(T).@"struct".fields;
    if (params.len != fields.len) return Error.InvalidParams;
    var out: T = undefined;
    inline for (fields, 0..) |f, i| {
        @field(out, f.name) = try coerce(f.type, params[i]);
    }
    return out;
}

/// Convert one JSON value to a field type, or InvalidParams on a type mismatch.
fn coerce(comptime T: type, v: std.json.Value) Error!T {
    switch (@typeInfo(T)) {
        .int => {
            if (v != .integer) return Error.InvalidParams;
            return std.math.cast(T, v.integer) orelse Error.InvalidParams;
        },
        .float => return switch (v) {
            .float => |x| @floatCast(x),
            .integer => |n| @floatFromInt(n),
            else => Error.InvalidParams,
        },
        .bool => {
            if (v != .bool) return Error.InvalidParams;
            return v.bool;
        },
        .pointer => { // []const u8
            if (v != .string) return Error.InvalidParams;
            return v.string;
        },
        else => @compileError("unsupported param type: " ++ @typeName(T)),
    }
}

const Allocator = std.mem.Allocator;

/// Build a JSON array Value from Value literals for tests.
fn jsonArray(allocator: Allocator, values: []const std.json.Value) !std.json.Value {
    var arr = std.json.Array.init(allocator);
    try arr.appendSlice(values);
    return .{ .array = arr };
}

test "fromJson mouse_move gives typed x, y" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const v = try jsonArray(arena.allocator(), &.{
        .{ .integer = 42 },
        .{ .string = "mouse_move" },
        .{ .integer = 200 },
        .{ .integer = 300 },
    });

    const req = try Request.fromJson(v);
    try std.testing.expectEqual(@as(u32, 42), req.id);
    try std.testing.expectEqual(@as(i32, 200), req.payload.mouse_move.x);
    try std.testing.expectEqual(@as(i32, 300), req.payload.mouse_move.y);
}

test "fromJson keyboard_type_text gives typed string" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const v = try jsonArray(arena.allocator(), &.{
        .{ .integer = 1 },
        .{ .string = "keyboard_type_text" },
        .{ .string = "ciao" },
    });

    const req = try Request.fromJson(v);
    try std.testing.expectEqualStrings("ciao", req.payload.keyboard_type_text.text);
}

test "fromJson no-param command" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const v = try jsonArray(arena.allocator(), &.{ .{ .integer = 5 }, .{ .string = "system_info" } });

    const req = try Request.fromJson(v);
    try std.testing.expectEqual(Cmd.system_info, req.payload);
}

test "fromJson rejects non-array" {
    try std.testing.expectError(Error.InvalidRequest, Request.fromJson(.{ .integer = 7 }));
}

test "fromJson rejects wrong arity" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const v = try jsonArray(arena.allocator(), &.{ .{ .integer = 1 }, .{ .string = "mouse_move" }, .{ .integer = 200 } });
    try std.testing.expectError(Error.InvalidParams, Request.fromJson(v));
}

test "fromJson rejects wrong type" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const v = try jsonArray(arena.allocator(), &.{ .{ .integer = 1 }, .{ .string = "mouse_move" }, .{ .integer = 200 }, .{ .string = "x" } });
    try std.testing.expectError(Error.InvalidParams, Request.fromJson(v));
}

test "fromJson rejects unknown command" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const v = try jsonArray(arena.allocator(), &.{ .{ .integer = 1 }, .{ .string = "fly_to_moon" } });
    try std.testing.expectError(Error.UnknownCommand, Request.fromJson(v));
}

test "fromJson rejects bad envelope" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const v = try jsonArray(arena.allocator(), &.{.{ .string = "no_id" }}); // missing id+cmd shape
    try std.testing.expectError(Error.InvalidRequest, Request.fromJson(v));
}
