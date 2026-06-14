const std = @import("std");
const JsonParser = @import("JsonParser.zig");
const Request = @import("Request.zig");
const RequestHandler = @import("RequestHandler.zig");
const Response = @import("Response.zig");

const Runner = @This();

allocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
parser: JsonParser,
request_handler: RequestHandler,

/// Invoked with response bytes to write out, plus the opaque `ctx` passed to
/// handle(). May be called several times per handle() — emit every slice in
/// order to reconstruct the full output.
pub const WriteCallback = *const fn (ctx: *anyopaque, bytes: []const u8) void;

const terminator = [_]u8{0};

/// `mouse`/`keyboard` are caller-owned C handles, forwarded to the
/// RequestHandler. The Runner does not free them.
pub fn init(allocator: std.mem.Allocator, mouse: ?*anyopaque, keyboard: ?*anyopaque) Runner {
    return .{
        .allocator = allocator,
        .arena = std.heap.ArenaAllocator.init(allocator),
        .parser = JsonParser.init(allocator),
        .request_handler = RequestHandler.init(mouse, keyboard),
    };
}

pub fn deinit(self: *Runner) void {
    self.arena.deinit();
    self.parser.deinit();
}

/// Feed a chunk of input. Dispatches every complete request it yields and
/// passes each Response's NUL-terminated JSON bytes to `writeCallback` (along
/// with `ctx`). An empty `data` signals end of stream (nothing to do).
pub fn handle(self: *Runner, data: []const u8, writeCallback: WriteCallback, ctx: *anyopaque) !void {
    if (data.len == 0) return; // end of stream
    defer _ = self.arena.reset(.retain_capacity);
    const a = self.arena.allocator();

    for (try self.parser.parse(a, data)) |value| {
        // A bad request (unknown command, wrong params, bad envelope) must not
        // take the driver down: reply with an error and keep going. Only
        // allocation failure is fatal.
        const response = self.dispatch(a, value) catch |err| switch (err) {
            error.OutOfMemory => return err,
            else => Response.failure(requestId(value), "invalid request"),
        };
        const json = try std.json.Stringify.valueAlloc(a, response, .{});
        writeCallback(ctx, json);
        writeCallback(ctx, &terminator); // frame terminator, matching requests
    }
}

fn dispatch(self: *Runner, a: std.mem.Allocator, value: std.json.Value) !Response {
    return self.request_handler.handle(a, try Request.fromJson(value));
}

/// Best-effort request id for error replies; 0 when the envelope lacks one.
fn requestId(value: std.json.Value) u32 {
    if (value == .array and value.array.items.len > 0 and value.array.items[0] == .integer) {
        return std.math.cast(u32, value.array.items[0].integer) orelse 0;
    }
    return 0;
}

const Collector = struct {
    list: std.ArrayList(u8) = .empty,
    allocator: std.mem.Allocator,
    fn write(ctx: *anyopaque, bytes: []const u8) void {
        const self: *Collector = @ptrCast(@alignCast(ctx));
        self.list.appendSlice(self.allocator, bytes) catch unreachable;
    }
};

test "a bad request gets an error reply, not a crash" {
    var collector = Collector{ .allocator = std.testing.allocator };
    defer collector.list.deinit(std.testing.allocator);

    var runner = Runner.init(std.testing.allocator, null, null);
    defer runner.deinit();

    // Unknown command: fromJson rejects it before any device call.
    try runner.handle("[7,\"fly_to_moon\"]\x00", Collector.write, &collector);

    try std.testing.expect(std.mem.indexOf(u8, collector.list.items, "\"id\":7") != null);
    try std.testing.expect(std.mem.indexOf(u8, collector.list.items, "\"error\":\"invalid request\"") != null);
}

test "valid requests get one NUL-framed ok reply each" {
    var collector = Collector{ .allocator = std.testing.allocator };
    defer collector.list.deinit(std.testing.allocator);

    var runner = Runner.init(std.testing.allocator, null, null);
    defer runner.deinit();

    // ignore_all is a device-free no-op that replies ok.
    try runner.handle("[1,\"ignore_all\"]\x00[2,\"ignore_all\"]\x00", Collector.write, &collector);

    try std.testing.expectEqual(@as(usize, 2), std.mem.count(u8, collector.list.items, "\x00"));
    try std.testing.expect(std.mem.indexOf(u8, collector.list.items, "{\"id\":1,\"error\":null,\"payload\":null}") != null);
    try std.testing.expect(std.mem.indexOf(u8, collector.list.items, "{\"id\":2,\"error\":null,\"payload\":null}") != null);
}
