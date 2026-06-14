//! fcx_system_info: fills the caller's struct from Win32.
const std = @import("std");
const w = @import("win32.zig");

const STR_MAX = 256;

const SystemInfo = extern struct {
    os_version: [STR_MAX]u8,
    username: [STR_MAX]u8,
    full_user_name: [STR_MAX]u8,
    home_directory: [STR_MAX]u8,
    hostname: [STR_MAX]u8,
};

extern "advapi32" fn GetUserNameA(lpBuffer: [*]u8, pcbBuffer: *w.DWORD) callconv(w.WINAPI) w.BOOL;
extern "kernel32" fn GetComputerNameA(lpBuffer: [*]u8, nSize: *w.DWORD) callconv(w.WINAPI) w.BOOL;
extern "kernel32" fn GetEnvironmentVariableA(lpName: [*:0]const u8, lpBuffer: [*]u8, nSize: w.DWORD) callconv(w.WINAPI) w.DWORD;

fn setField(field: *[STR_MAX]u8, value: []const u8) void {
    const n = @min(value.len, STR_MAX - 1);
    @memcpy(field[0..n], value[0..n]);
    field[n] = 0;
}

pub export fn fcx_system_info(info: *SystemInfo) callconv(.c) void {
    info.* = std.mem.zeroes(SystemInfo);

    setField(&info.os_version, "Windows");

    var size: w.DWORD = STR_MAX;
    if (GetUserNameA(&info.username, &size) == 0) info.username[0] = 0;
    // No cheap portable display name; fall back to the login name.
    setField(&info.full_user_name, std.mem.sliceTo(&info.username, 0));

    size = STR_MAX;
    if (GetComputerNameA(&info.hostname, &size) == 0) info.hostname[0] = 0;

    const n = GetEnvironmentVariableA("USERPROFILE", &info.home_directory, STR_MAX);
    if (n == 0 or n >= STR_MAX) info.home_directory[0] = 0;
}

test "setField truncates and NUL-terminates" {
    var f: [STR_MAX]u8 = undefined;
    setField(&f, "abc");
    try std.testing.expectEqualStrings("abc", std.mem.sliceTo(&f, 0));

    setField(&f, "x" ** (STR_MAX + 10));
    try std.testing.expectEqual(@as(u8, 0), f[STR_MAX - 1]);
    try std.testing.expectEqual(@as(usize, STR_MAX - 1), std.mem.sliceTo(&f, 0).len);
}
