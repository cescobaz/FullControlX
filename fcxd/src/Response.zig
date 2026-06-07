const std = @import("std");

const Response = @This();

/// Echoes the id of the request this answers.
id: u32,
payload: Payload,

/// Response content. A union so it can grow per response kind; for now the
/// only variant carries an optional error message (null = success).
pub const Payload = union(enum) {
    err: ?[]const u8,
};

/// Successful response with no error.
pub fn ok(id: u32) Response {
    return .{ .id = id, .payload = .{ .err = null } };
}

/// Failure response carrying a message.
pub fn failure(id: u32, message: []const u8) Response {
    return .{ .id = id, .payload = .{ .err = message } };
}

/// Custom JSON shape: {"id": <id>, "error": null | "<msg>"}.
pub fn jsonStringify(self: Response, jw: anytype) !void {
    try jw.beginObject();
    try jw.objectField("id");
    try jw.write(self.id);
    switch (self.payload) {
        .err => |maybe| {
            try jw.objectField("error");
            try jw.write(maybe); // ?[]const u8 -> null or escaped string
        },
    }
    try jw.endObject();
}

test "ok response has null error" {
    const r = Response.ok(42);
    try std.testing.expectEqual(@as(u32, 42), r.id);
    try std.testing.expect(r.payload.err == null);
}

test "failure response carries message" {
    const r = Response.failure(7, "mouse failed");
    try std.testing.expectEqual(@as(u32, 7), r.id);
    try std.testing.expectEqualStrings("mouse failed", r.payload.err.?);
}

test "json shape ok and failure" {
    const ok_json = try std.json.Stringify.valueAlloc(std.testing.allocator, Response.ok(42), .{});
    defer std.testing.allocator.free(ok_json);
    try std.testing.expectEqualStrings("{\"id\":42,\"error\":null}", ok_json);

    const fail_json = try std.json.Stringify.valueAlloc(std.testing.allocator, Response.failure(7, "bad"), .{});
    defer std.testing.allocator.free(fail_json);
    try std.testing.expectEqualStrings("{\"id\":7,\"error\":\"bad\"}", fail_json);
}
