const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const host_is_darwin = @import("builtin").os.tag.isDarwin();

    // macOS deployment target is 10.11. The OS tag must be set explicitly (.macos)
    // alongside os_version_min, otherwise the target resolves to an unspecified
    // "native" OS. Gated to darwin hosts so native Linux builds are unaffected. This
    // stamps the binary's LC_VERSION_MIN_MACOSX = 10.11 so it can actually run on that
    // deployment target.
    const default_target: std.Target.Query = if (host_is_darwin)
        .{
            .os_tag = .macos,
            .os_version_min = .{ .semver = .{ .major = 10, .minor = 11, .patch = 0 } },
        }
    else
        .{};
    const target = b.standardTargetOptions(.{ .default_target = default_target });
    const optimize = b.standardOptimizeOption(.{});

    const is_darwin = target.result.os.tag.isDarwin();

    // Pinning os_version_min makes the target "non-native", so Zig no longer
    // auto-injects the macOS SDK for system headers, frameworks and libSystem. Point
    // each module at the active SDK explicitly. (A global b.sysroot would also rebase
    // json-c's homebrew -L path under the SDK and break it, so set paths per module.)
    var sdk_frameworks: ?std.Build.LazyPath = null;
    var sdk_include: ?std.Build.LazyPath = null;
    var sdk_lib: ?std.Build.LazyPath = null;
    if (host_is_darwin and is_darwin) {
        const sdk = std.mem.trimEnd(u8, b.run(&.{ "xcrun", "--show-sdk-path" }), " \n\r");
        sdk_frameworks = .{ .cwd_relative = b.pathJoin(&.{ sdk, "System/Library/Frameworks" }) };
        sdk_include = .{ .cwd_relative = b.pathJoin(&.{ sdk, "usr/include" }) };
        sdk_lib = .{ .cwd_relative = b.pathJoin(&.{ sdk, "usr/lib" }) };
    }

    // Stay on strict ISO c99. On glibc (Linux), strict c99 (__STRICT_ANSI__) hides the
    // POSIX/BSD extensions the sources use (gmtime_r, clock_gettime, struct timespec,
    // CLOCK_* ids), so define _DEFAULT_SOURCE to re-expose them — it's exactly the
    // feature-test macro gnu99 would auto-define. Darwin's libc exposes these by default
    // and ignores _DEFAULT_SOURCE, so it's a no-op there and we leave it off.
    const cflags: []const []const u8 = if (is_darwin)
        &.{"-std=c99"}
    else
        &.{ "-std=c99", "-D_DEFAULT_SOURCE" };

    // FCX_LOG_LEVEL: 4 (debug) in Debug builds, 3 (info) otherwise. logger.h has no
    // default, so leaving it undefined would disable all logging.
    const log_level = if (optimize == .Debug) "4" else "3";

    const lib_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    // System libraries are linked on the executable module, not here: linking them
    // on the static-library module bakes the system .so files into libFullControlX_s.a
    // as archive members, which the final link then rejects ("neither ET_REL nor LLVM
    // bitcode"). The lib's sources still compile because all required headers (json-c,
    // keymap, kbdfile) live under the default /usr/include search path.
    lib_mod.addCMacro("FCX_LOG_LEVEL", log_level);
    lib_mod.addCSourceFiles(.{
        .root = b.path("src"),
        .files = &.{
            "logger.c",
            "fcx_request_handler.c",
            "fcx_app.c",
        },
        .flags = cflags,
    });
    if (is_darwin) {
        if (sdk_frameworks) |p| lib_mod.addSystemFrameworkPath(p);
        if (sdk_include) |p| lib_mod.addSystemIncludePath(p);
        // The lib's sources include <json-c/json.h>. Pinning os_version_min drops Zig's
        // default native search paths, and homebrew's json-c lives outside the SDK
        // (/opt/homebrew/opt/json-c/include), so add its includedir explicitly. The lib
        // only needs the header, not the link — json-c is linked on the exe module, as
        // linking system libs here would bake .so members into the static archive. Query
        // pkg-config (already a hard dep, since the exe's linkSystemLibrary uses it).
        if (host_is_darwin) {
            const inc = std.mem.trimEnd(u8, b.run(&.{ "pkg-config", "--variable=includedir", "json-c" }), " \n\r");
            lib_mod.addSystemIncludePath(.{ .cwd_relative = inc });
        }
        lib_mod.linkFramework("CoreFoundation", .{});
        lib_mod.linkFramework("CoreGraphics", .{});
        lib_mod.linkFramework("AppKit", .{});
        lib_mod.linkFramework("IOKit", .{});
        lib_mod.linkFramework("Carbon", .{});
        lib_mod.addCSourceFiles(.{
            .root = b.path("src/mac"),
            .files = &.{
                "fcx_mouse.c",
                "fcx_system.m",
                "fcx_keyboard_symbols_map.c",
                "fcx_keyboard.c",
                "fcx_apps.m",
                "fcx_io_hid.c",
            },
            .flags = cflags,
        });
    } else {
        lib_mod.addCSourceFiles(.{
            .root = b.path("src/linux"),
            .files = &.{
                "fcx_mouse.c",
                "fcx_system.c",
                "fcx_keyboard_map.c",
                "fcx_keyboard.c",
                "fcx_apps.c",
            },
            .flags = cflags,
        });
    }

    const lib = b.addLibrary(.{
        .name = "FullControlX_s",
        .root_module = lib_mod,
        .linkage = .static,
    });
    b.installArtifact(lib);

    const exe_mod = b.createModule(.{
        // On darwin the entry point stays ObjC (main.m, added below as a C source
        // with no Zig root); the Zig pipeline is linked in as a static library
        // (runner_lib) and called over its C ABI. On Linux main is Zig (main.zig),
        // so it is the module root and imports the Runner directly — no C shim.
        .root_source_file = if (is_darwin) null else b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    exe_mod.addCMacro("FCX_LOG_LEVEL", log_level);
    exe_mod.linkLibrary(lib);
    exe_mod.linkSystemLibrary("json-c", .{ .preferred_link_mode = .static });
    if (is_darwin) {
        if (sdk_frameworks) |p| exe_mod.addSystemFrameworkPath(p);
        if (sdk_include) |p| exe_mod.addSystemIncludePath(p);
        if (sdk_lib) |p| exe_mod.addLibraryPath(p);
        // main.m's @cInclude("fcx_app.h") needs src/ on the include path. The json-c
        // includedir that fcx_app.h pulls in via <json-c/json.h> is already added by
        // linkSystemLibrary("json-c") above (-I from pkg-config), so don't re-add it.
        exe_mod.addIncludePath(b.path("src"));
        exe_mod.addCSourceFile(.{ .file = b.path("src/mac/main.m"), .flags = cflags });

        // Zig request pipeline as a static library, called from main.m via its
        // C ABI (RunnerC.zig / fcx_runner.h). It @cImports fcx_mouse.h, so it
        // needs src/ and the SDK headers; the fcx_mouse_* symbols it references
        // resolve at the final link against the C lib above.
        const runner_mod = b.createModule(.{
            .root_source_file = b.path("src/RunnerC.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        if (sdk_include) |p| runner_mod.addSystemIncludePath(p);
        runner_mod.addIncludePath(b.path("src"));
        const runner_lib = b.addLibrary(.{
            .name = "fcx_runner",
            .root_module = runner_mod,
            .linkage = .static,
        });
        exe_mod.linkLibrary(runner_lib);
    } else {
        exe_mod.linkSystemLibrary("keymap", .{});
        exe_mod.linkSystemLibrary("kbdfile", .{});
        // main.zig (and the Runner it imports) @cImports fcx_mouse.h /
        // fcx_keyboard.h; the fcx_* symbols resolve at the final link against the
        // C lib above. json-c's includedir is already on the path via the
        // linkSystemLibrary("json-c") -I from pkg-config.
        exe_mod.addIncludePath(b.path("src"));
    }

    const exe = b.addExecutable(.{
        .name = "FullControlX",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
