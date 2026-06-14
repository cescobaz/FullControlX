//! Hand-declared Win32 bindings used by the Windows platform modules.
const std = @import("std");

pub const WINAPI = std.builtin.CallingConvention.winapi;
pub const BOOL = c_int;
pub const HANDLE = *anyopaque;
pub const DWORD = u32;
pub const WORD = u16;
pub const LONG = i32;
pub const ULONG_PTR = usize;

pub const POINT = extern struct { x: LONG, y: LONG };

pub const MOUSEINPUT = extern struct {
    dx: LONG,
    dy: LONG,
    mouseData: DWORD,
    dwFlags: DWORD,
    time: DWORD,
    dwExtraInfo: ULONG_PTR,
};

pub const KEYBDINPUT = extern struct {
    wVk: WORD,
    wScan: WORD,
    dwFlags: DWORD,
    time: DWORD,
    dwExtraInfo: ULONG_PTR,
};

pub const INPUT = extern struct {
    type: DWORD,
    u: extern union {
        mi: MOUSEINPUT,
        ki: KEYBDINPUT,
    },
};

pub const INPUT_MOUSE: DWORD = 0;
pub const INPUT_KEYBOARD: DWORD = 1;

pub const MOUSEEVENTF_MOVE: DWORD = 0x0001;
pub const MOUSEEVENTF_LEFTDOWN: DWORD = 0x0002;
pub const MOUSEEVENTF_LEFTUP: DWORD = 0x0004;
pub const MOUSEEVENTF_RIGHTDOWN: DWORD = 0x0008;
pub const MOUSEEVENTF_RIGHTUP: DWORD = 0x0010;
pub const MOUSEEVENTF_WHEEL: DWORD = 0x0800;
pub const MOUSEEVENTF_HWHEEL: DWORD = 0x1000;
pub const WHEEL_DELTA: LONG = 120;

pub const KEYEVENTF_KEYUP: DWORD = 0x0002;
pub const KEYEVENTF_UNICODE: DWORD = 0x0004;

pub const STD_INPUT_HANDLE: DWORD = @bitCast(@as(i32, -10));
pub const STD_OUTPUT_HANDLE: DWORD = @bitCast(@as(i32, -11));

pub extern "user32" fn SendInput(cInputs: DWORD, pInputs: [*]INPUT, cbSize: c_int) callconv(WINAPI) DWORD;
pub extern "user32" fn GetCursorPos(lpPoint: *POINT) callconv(WINAPI) BOOL;
pub extern "kernel32" fn GetStdHandle(nStdHandle: DWORD) callconv(WINAPI) HANDLE;
pub extern "kernel32" fn ReadFile(hFile: HANDLE, lpBuffer: [*]u8, n: DWORD, read: *DWORD, overlapped: ?*anyopaque) callconv(WINAPI) BOOL;
pub extern "kernel32" fn WriteFile(hFile: HANDLE, lpBuffer: [*]const u8, n: DWORD, written: *DWORD, overlapped: ?*anyopaque) callconv(WINAPI) BOOL;

/// Send a single INPUT event. Returns true if the event was inserted.
pub fn send(input: *INPUT) bool {
    return SendInput(1, @ptrCast(input), @sizeOf(INPUT)) == 1;
}

test "INPUT layout matches the Win32 ABI" {
    if (@sizeOf(usize) == 8) {
        try std.testing.expectEqual(@as(usize, 32), @sizeOf(MOUSEINPUT));
        try std.testing.expectEqual(@as(usize, 40), @sizeOf(INPUT));
    } else {
        try std.testing.expectEqual(@as(usize, 24), @sizeOf(MOUSEINPUT));
        try std.testing.expectEqual(@as(usize, 28), @sizeOf(INPUT));
    }
}
