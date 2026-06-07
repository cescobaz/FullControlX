//! C ABI shim around Runner, so the ObjC entry point (main.m) can drive the
//! Zig request pipeline. See fcx_runner.h for the C declarations.
const std = @import("std");
const Runner = @import("Runner.zig");

/// C write callback: `write_cb(ctx, buf, len)`.
const CWriteFn = *const fn (ctx: ?*anyopaque, buf: [*]const u8, len: usize) callconv(.c) void;

/// Carries the C callback + ctx through Runner's opaque-context callback.
const WriteCtx = struct {
    cb: CWriteFn,
    ctx: ?*anyopaque,
};

fn trampoline(zig_ctx: *anyopaque, bytes: []const u8) void {
    const wc: *WriteCtx = @ptrCast(@alignCast(zig_ctx));
    wc.cb(wc.ctx, bytes.ptr, bytes.len);
}

/// Allocate and initialize a Runner. Returns null on OOM.
export fn fcx_runner_create() callconv(.c) ?*Runner {
    const allocator = std.heap.c_allocator;
    const runner = allocator.create(Runner) catch return null;
    runner.* = Runner.init(allocator);
    return runner;
}

export fn fcx_runner_destroy(runner: ?*Runner) callconv(.c) void {
    const r = runner orelse return;
    r.deinit();
    std.heap.c_allocator.destroy(r);
}

/// Feed `data[0..len]` to the runner. Response bytes are delivered via
/// `write_cb(ctx, ...)`. Returns 0 on success, -1 on error.
export fn fcx_runner_handle(
    runner: ?*Runner,
    data: [*]const u8,
    len: usize,
    write_cb: CWriteFn,
    ctx: ?*anyopaque,
) callconv(.c) c_int {
    const r = runner orelse return -1;
    var wc = WriteCtx{ .cb = write_cb, .ctx = ctx };
    r.handle(data[0..len], trampoline, &wc) catch return -1;
    return 0;
}
