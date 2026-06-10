const std = @import("std");
const JsonParser = @import("JsonParser.zig");
const Request = @import("Request.zig");
const RequestHandler = @import("RequestHandler.zig");

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
        const request = try Request.fromJson(value);
        const response = try self.request_handler.handle(a, request);
        const json = try std.json.Stringify.valueAlloc(a, response, .{});
        writeCallback(ctx, json);
        writeCallback(ctx, &terminator); // frame terminator, matching requests
    }
}
