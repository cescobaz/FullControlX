const std = @import("std");
const Request = @import("Request.zig");
const Response = @import("Response.zig");

const c = @cImport({
    @cInclude("fcx_mouse.h");
});

pub fn handle(request: Request) !Response {
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

        // System / apps
        .system_info,
        .ui_apps,
        .apps_observe,
        .ignore_all,
        => {},
    }
    return Response.ok(request.id);
}
