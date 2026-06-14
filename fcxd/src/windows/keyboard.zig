//! fcx_keyboard_* over Win32 SendInput: Unicode text + virtual-key symbols.
const std = @import("std");
const w = @import("win32.zig");

var sentinel: u8 = 0;

pub export fn fcx_keyboard_create(keymap_name: [*:0]const u8) callconv(.c) ?*anyopaque {
    _ = keymap_name; // layout-independent: text is sent as Unicode.
    return &sentinel;
}

pub export fn fcx_keyboard_free(keyboard: ?*anyopaque) callconv(.c) void {
    _ = keyboard;
}

fn sendKey(vk: w.WORD, scan: w.WORD, flags: w.DWORD) void {
    var input = w.INPUT{ .type = w.INPUT_KEYBOARD, .u = .{ .ki = .{
        .wVk = vk,
        .wScan = scan,
        .dwFlags = flags,
        .time = 0,
        .dwExtraInfo = 0,
    } } };
    _ = w.send(&input);
}

fn typeUnit(unit: u16) void {
    sendKey(0, unit, w.KEYEVENTF_UNICODE);
    sendKey(0, unit, w.KEYEVENTF_UNICODE | w.KEYEVENTF_KEYUP);
}

pub export fn fcx_keyboard_type_text(keyboard: ?*anyopaque, text: [*:0]const u8) callconv(.c) c_int {
    _ = keyboard;
    const s = std.mem.span(text);
    const view = std.unicode.Utf8View.init(s) catch return 1;
    var it = view.iterator();
    while (it.nextCodepoint()) |cp| {
        if (cp <= 0xFFFF) {
            typeUnit(@intCast(cp));
        } else {
            const v = cp - 0x10000;
            typeUnit(@intCast(0xD800 + (v >> 10)));
            typeUnit(@intCast(0xDC00 + (v & 0x3FF)));
        }
    }
    return 0;
}

// Names match the symbols the app sends (ToolsLive). Brightness has no
// SendInput virtual-key on Windows, so it stays unsupported.
fn symbolToVk(name: []const u8) ?w.WORD {
    const map = .{
        .{ "left", 0x25 },       .{ "up", 0x26 },       .{ "right", 0x27 }, .{ "down", 0x28 },
        .{ "volumedown", 0xAE }, .{ "volumeup", 0xAF },  .{ "mute", 0xAD },
        .{ "back", 0xB1 },       .{ "playpause", 0xB3 }, .{ "forward", 0xB0 },
    };
    inline for (map) |entry| {
        if (std.mem.eql(u8, name, entry[0])) return entry[1];
    }
    return null;
}

pub export fn fcx_keyboard_type_symbol(keyboard: ?*anyopaque, symbol: [*:0]const u8) callconv(.c) c_int {
    _ = keyboard;
    const vk = symbolToVk(std.mem.span(symbol)) orelse return 1;
    sendKey(vk, 0, 0);
    sendKey(vk, 0, w.KEYEVENTF_KEYUP);
    return 0;
}

test "symbolToVk maps the app's symbols and rejects unsupported" {
    try std.testing.expectEqual(@as(?w.WORD, 0xAF), symbolToVk("volumeup"));
    try std.testing.expectEqual(@as(?w.WORD, 0xB3), symbolToVk("playpause"));
    try std.testing.expectEqual(@as(?w.WORD, 0x27), symbolToVk("right"));
    try std.testing.expectEqual(@as(?w.WORD, null), symbolToVk("brightnessup"));
}
