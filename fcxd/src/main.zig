//! Linux entry point. Unlike macOS (which keeps an ObjC main.m and reaches the
//! Zig pipeline over the C ABI in RunnerC.zig), Linux drives the Runner
//! directly: main is Zig, so it imports Runner and calls it natively.
//!
//! fcx_app (C) owns the locale setup, IO fds, buffer and the mouse/keyboard
//! devices; the runner borrows app.mouse / app.keyboard.
const std = @import("std");
const Runner = @import("Runner.zig");

const c = @cImport({
    @cInclude("unistd.h");
    @cInclude("fcx_app.h");
});

/// Runner write callback: ctx points at the output fd.
fn writeResponse(ctx: *anyopaque, bytes: []const u8) void {
    const fd: *const c_int = @ptrCast(@alignCast(ctx));
    _ = c.write(fd.*, bytes.ptr, bytes.len);
}

pub fn main() !void {
    const argc: c_int = @intCast(std.os.argv.len);
    const argv: [*c][*c]u8 = @ptrCast(std.os.argv.ptr);
    const app = c.fcx_app_init(argc, argv) orelse return error.AppInitFailed;
    defer c.fcx_app_free(app);

    var runner = Runner.init(std.heap.c_allocator, app.*.mouse, app.*.keyboard);
    defer runner.deinit();

    while (true) {
        const r = c.read(app.*.input, app.*.buffer, app.*.buffer_size);
        if (r == 0) {
            std.log.info("input ends, terminating", .{});
            break;
        }
        const chunk = app.*.buffer[0..@intCast(r)];
        runner.handle(chunk, writeResponse, &app.*.output) catch |err| {
            std.log.err("runner handle error: {}", .{err});
            std.process.exit(1);
        };
    }
}
