const std = @import("std");
const Request = @import("Request.zig");
const Response = @import("Response.zig");

const c = @cImport({
    @cInclude("fcx_mouse.h");
    @cInclude("fcx_system.h");
});

pub fn handle(allocator: std.mem.Allocator, request: Request) !Response {
    switch (request.payload) {
        // Mouse
        .mouse_move => |p| _ = c.fcx_mouse_move(p.x, p.y),
        .mouse_drag => |p| _ = c.fcx_mouse_drag(p.x, p.y),
        .mouse_scroll_wheel => |p| _ = c.fcx_mouse_scroll_wheel(p.x, p.y),
        .mouse_left_down => _ = c.fcx_mouse_left_down(),
        .mouse_left_up => _ = c.fcx_mouse_left_up(),
        .mouse_left_click => _ = c.fcx_mouse_left_click(),
        .mouse_right_click => _ = c.fcx_mouse_right_click(),
        .mouse_double_click => _ = c.fcx_mouse_double_click(),

        // Keyboard
        .keyboard_type_text => |p| {
            _ = p.text;
        },
        .keyboard_type_symbol => |p| {
            _ = p.symbol;
        },

        // System
        .system_info => return systemInfo(allocator, request.id),

        // Apps
        .ui_apps,
        .apps_observe,
        .ignore_all,
        => {},
    }
    return Response.ok(request.id);
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
