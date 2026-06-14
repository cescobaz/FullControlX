//! fcx_mouse_* over Win32 SendInput. Returns 0 on success (C contract).
const std = @import("std");
const w = @import("win32.zig");

var sentinel: u8 = 0;

pub const Location = extern struct { x: c_int, y: c_int };

fn mouseEvent(flags: w.DWORD, dx: w.LONG, dy: w.LONG, data: w.DWORD) c_int {
    var input = w.INPUT{ .type = w.INPUT_MOUSE, .u = .{ .mi = .{
        .dx = dx,
        .dy = dy,
        .mouseData = data,
        .dwFlags = flags,
        .time = 0,
        .dwExtraInfo = 0,
    } } };
    return if (w.send(&input)) 0 else 1;
}

pub export fn fcx_mouse_create() callconv(.c) ?*anyopaque {
    return &sentinel;
}

pub export fn fcx_mouse_free(mouse: ?*anyopaque) callconv(.c) void {
    _ = mouse;
}

pub export fn fcx_mouse_location(mouse: ?*anyopaque) callconv(.c) Location {
    _ = mouse;
    var p: w.POINT = undefined;
    _ = w.GetCursorPos(&p);
    return .{ .x = p.x, .y = p.y };
}

pub export fn fcx_mouse_move(mouse: ?*anyopaque, x: c_int, y: c_int) callconv(.c) c_int {
    _ = mouse;
    return mouseEvent(w.MOUSEEVENTF_MOVE, x, y, 0);
}

// Button is already held during a drag, so it's just a relative move.
pub export fn fcx_mouse_drag(mouse: ?*anyopaque, x: c_int, y: c_int) callconv(.c) c_int {
    return fcx_mouse_move(mouse, x, y);
}

pub export fn fcx_mouse_left_down(mouse: ?*anyopaque) callconv(.c) c_int {
    _ = mouse;
    return mouseEvent(w.MOUSEEVENTF_LEFTDOWN, 0, 0, 0);
}

pub export fn fcx_mouse_left_up(mouse: ?*anyopaque) callconv(.c) c_int {
    _ = mouse;
    return mouseEvent(w.MOUSEEVENTF_LEFTUP, 0, 0, 0);
}

pub export fn fcx_mouse_left_click(mouse: ?*anyopaque) callconv(.c) c_int {
    if (fcx_mouse_left_down(mouse) != 0) return 1;
    return fcx_mouse_left_up(mouse);
}

pub export fn fcx_mouse_right_down(mouse: ?*anyopaque) callconv(.c) c_int {
    _ = mouse;
    return mouseEvent(w.MOUSEEVENTF_RIGHTDOWN, 0, 0, 0);
}

pub export fn fcx_mouse_right_up(mouse: ?*anyopaque) callconv(.c) c_int {
    _ = mouse;
    return mouseEvent(w.MOUSEEVENTF_RIGHTUP, 0, 0, 0);
}

pub export fn fcx_mouse_right_click(mouse: ?*anyopaque) callconv(.c) c_int {
    if (fcx_mouse_right_down(mouse) != 0) return 1;
    return fcx_mouse_right_up(mouse);
}

pub export fn fcx_mouse_double_click(mouse: ?*anyopaque) callconv(.c) c_int {
    if (fcx_mouse_left_click(mouse) != 0) return 1;
    return fcx_mouse_left_click(mouse);
}

pub export fn fcx_mouse_scroll_wheel(mouse: ?*anyopaque, x: c_int, y: c_int) callconv(.c) c_int {
    _ = mouse;
    if (y != 0) {
        const data: w.DWORD = @bitCast(@as(w.LONG, y) * w.WHEEL_DELTA);
        if (mouseEvent(w.MOUSEEVENTF_WHEEL, 0, 0, data) != 0) return 1;
    }
    if (x != 0) {
        const data: w.DWORD = @bitCast(@as(w.LONG, x) * w.WHEEL_DELTA);
        if (mouseEvent(w.MOUSEEVENTF_HWHEEL, 0, 0, data) != 0) return 1;
    }
    return 0;
}
