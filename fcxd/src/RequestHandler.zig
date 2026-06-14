const std = @import("std");
const Request = @import("Request.zig");
const Response = @import("Response.zig");

const c = @cImport({
    @cInclude("fcx_mouse.h");
    @cInclude("fcx_keyboard.h");
    @cInclude("fcx_system.h");
});

const RequestHandler = @This();

mouse: ?*c.fcx_mouse_t,
keyboard: ?*c.fcx_keyboard_t,

/// The mouse/keyboard handles are owned by the caller (created and freed in
/// main); the handler just borrows them.
pub fn init(mouse: ?*c.fcx_mouse_t, keyboard: ?*c.fcx_keyboard_t) RequestHandler {
    return .{ .mouse = mouse, .keyboard = keyboard };
}

pub fn handle(self: *RequestHandler, allocator: std.mem.Allocator, request: Request) !Response {
    const mouse = self.mouse;
    const keyboard = self.keyboard;
    // C device functions return 0 on success, non-zero on failure. Bail out
    // with an error Response as soon as one fails; otherwise fall through to
    // the ok Response below.
    const id = request.id;
    switch (request.payload) {
        // Mouse
        .mouse_move => |p| if (c.fcx_mouse_move(mouse, p.x, p.y) != 0)
            return Response.failure(id, "mouse_move failed"),
        .mouse_drag => |p| if (c.fcx_mouse_drag(mouse, p.x, p.y) != 0)
            return Response.failure(id, "mouse_drag failed"),
        .mouse_scroll_wheel => |p| if (c.fcx_mouse_scroll_wheel(mouse, p.x, p.y) != 0)
            return Response.failure(id, "mouse_scroll_wheel failed"),
        .mouse_left_down => if (c.fcx_mouse_left_down(mouse) != 0)
            return Response.failure(id, "mouse_left_down failed"),
        .mouse_left_up => if (c.fcx_mouse_left_up(mouse) != 0)
            return Response.failure(id, "mouse_left_up failed"),
        .mouse_left_click => if (c.fcx_mouse_left_click(mouse) != 0)
            return Response.failure(id, "mouse_left_click failed"),
        .mouse_right_click => if (c.fcx_mouse_right_click(mouse) != 0)
            return Response.failure(id, "mouse_right_click failed"),
        .mouse_double_click => if (c.fcx_mouse_double_click(mouse) != 0)
            return Response.failure(id, "mouse_double_click failed"),

        // Keyboard
        .keyboard_type_text => |p| {
            const text = try allocator.dupeZ(u8, p.text);
            if (c.fcx_keyboard_type_text(keyboard, text.ptr) != 0)
                return Response.failure(id, "keyboard_type_text failed");
        },
        .keyboard_type_symbol => |p| {
            const symbol = try allocator.dupeZ(u8, p.symbol);
            if (c.fcx_keyboard_type_symbol(keyboard, symbol.ptr) != 0)
                return Response.failure(id, "keyboard_type_symbol failed");
        },

        // System
        .system_info => return systemInfo(allocator, id),

        // No-op acknowledgement.
        .ignore_all => return Response.ok(id),

        // Apps — not yet implemented under the zig Runner.
        .ui_apps,
        .apps_observe,
        => return Response.failure(id, "command not implemented"),
    }
    return Response.ok(id);
}

/// Read system info from the C API and copy it into an allocator-owned
/// Response (the C struct is stack-local, so its strings must be duped).
fn systemInfo(allocator: std.mem.Allocator, id: u32) !Response {
    var info: c.fcx_system_info_t = undefined;
    c.fcx_system_info(&info);
    return .{ .id = id, .payload = .{ .system_info = .{
        .os_version = try dupeCStr(allocator, &info.os_version),
        .username = try dupeCStr(allocator, &info.username),
        .full_user_name = try dupeCStr(allocator, &info.full_user_name),
        .home_directory = try dupeCStr(allocator, &info.home_directory),
        .hostname = try dupeCStr(allocator, &info.hostname),
    } } }; // err defaults to null
}

/// Dupe a fixed-size, NUL-terminated C char buffer into an owned slice.
fn dupeCStr(allocator: std.mem.Allocator, buf: []const u8) ![]const u8 {
    return allocator.dupe(u8, std.mem.sliceTo(buf, 0));
}
