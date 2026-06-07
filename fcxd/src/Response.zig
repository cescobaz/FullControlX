const std = @import("std");

const Response = @This();

/// Echoes the id of the request this answers.
id: u32,
/// Error message, or null on success.
err: ?[]const u8 = null,
/// Optional data payload (null when the command returns no data).
payload: ?Payload = null,

/// Data content per response kind. A union so it can grow.
pub const Payload = union(enum) {
    system_info: SystemInfo,
};

pub const SystemInfo = struct {
    os_version: []const u8,
    username: []const u8,
    full_user_name: []const u8,
    home_directory: []const u8,
    hostname: []const u8,
};

/// Successful response with no data.
pub fn ok(id: u32) Response {
    return .{ .id = id };
}

/// Failure response carrying a message.
pub fn failure(id: u32, message: []const u8) Response {
    return .{ .id = id, .err = message };
}

/// JSON shape: {"id": <id>, "error": null | "<msg>", "payload": null | {...}}.
pub fn jsonStringify(self: Response, jw: anytype) !void {
    try jw.beginObject();
    try jw.objectField("id");
    try jw.write(self.id);
    try jw.objectField("error");
    try jw.write(self.err); // ?[]const u8 -> null or escaped string
    try jw.objectField("payload");
    if (self.payload) |payload| switch (payload) {
        .system_info => |si| try jw.write(si),
    } else {
        try jw.write(null);
    }
    try jw.endObject();
}

test "ok response has null error" {
    const r = Response.ok(42);
    try std.testing.expectEqual(@as(u32, 42), r.id);
    try std.testing.expect(r.err == null);
    try std.testing.expect(r.payload == null);
}

test "failure response carries message" {
    const r = Response.failure(7, "mouse failed");
    try std.testing.expectEqual(@as(u32, 7), r.id);
    try std.testing.expectEqualStrings("mouse failed", r.err.?);
}

test "json shape ok and failure" {
    const ok_json = try std.json.Stringify.valueAlloc(std.testing.allocator, Response.ok(42), .{});
    defer std.testing.allocator.free(ok_json);
    try std.testing.expectEqualStrings("{\"id\":42,\"error\":null,\"payload\":null}", ok_json);

    const fail_json = try std.json.Stringify.valueAlloc(std.testing.allocator, Response.failure(7, "bad"), .{});
    defer std.testing.allocator.free(fail_json);
    try std.testing.expectEqualStrings("{\"id\":7,\"error\":\"bad\",\"payload\":null}", fail_json);
}

test "json shape system_info" {
    const r = Response{ .id = 3, .payload = .{ .system_info = .{
        .os_version = "macOS 15.0",
        .username = "buro",
        .full_user_name = "Francesco",
        .home_directory = "/Users/buro",
        .hostname = "mac",
    } } };
    const json = try std.json.Stringify.valueAlloc(std.testing.allocator, r, .{});
    defer std.testing.allocator.free(json);
    try std.testing.expectEqualStrings(
        "{\"id\":3,\"error\":null,\"payload\":{\"os_version\":\"macOS 15.0\",\"username\":\"buro\",\"full_user_name\":\"Francesco\",\"home_directory\":\"/Users/buro\",\"hostname\":\"mac\"}}",
        json,
    );
}
