//! Windows entry point: own stdio (no POSIX fcx_app), Zig Runner, Zig devices.
const std = @import("std");
const Runner = @import("Runner.zig");
const mouse = @import("windows/mouse.zig");
const keyboard = @import("windows/keyboard.zig");
const w = @import("windows/win32.zig");

// Force the platform C-ABI exports (called by RequestHandler) into the binary.
comptime {
    _ = mouse;
    _ = keyboard;
    _ = @import("windows/system.zig");
}

fn writeResponse(ctx: *anyopaque, bytes: []const u8) void {
    var written: w.DWORD = 0;
    _ = w.WriteFile(@ptrCast(ctx), bytes.ptr, @intCast(bytes.len), &written, null);
}

pub fn main() !void {
    const m = mouse.fcx_mouse_create();
    defer mouse.fcx_mouse_free(m);
    const kb = keyboard.fcx_keyboard_create("us");
    defer keyboard.fcx_keyboard_free(kb);

    var runner = Runner.init(std.heap.c_allocator, m, kb);
    defer runner.deinit();

    const stdin = w.GetStdHandle(w.STD_INPUT_HANDLE);
    const stdout = w.GetStdHandle(w.STD_OUTPUT_HANDLE);

    var buf: [4096]u8 = undefined;
    while (true) {
        var read: w.DWORD = 0;
        if (w.ReadFile(stdin, &buf, buf.len, &read, null) == 0) break;
        if (read == 0) break;
        runner.handle(buf[0..read], writeResponse, stdout) catch |err| {
            std.log.err("runner handle error: {}", .{err});
            std.process.exit(1);
        };
    }
}

test {
    // Pull every module's tests into `zig build test`.
    _ = @import("Runner.zig");
    _ = @import("Request.zig");
    _ = @import("Response.zig");
    _ = @import("JsonParser.zig");
    _ = @import("RequestHandler.zig");
    _ = @import("windows/win32.zig");
    _ = @import("windows/mouse.zig");
    _ = @import("windows/keyboard.zig");
    _ = @import("windows/system.zig");
}
