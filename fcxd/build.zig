const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const cflags = [_][]const u8{
        "-std=c99",
    };

    const config = b.addConfigHeader(.{
        .style = .{ .cmake = b.path("src/fullcontrol_x_config.h.in") },
        .include_path = "src/fullcontrol_x_config.h",
    }, cmake_config);

    const is_darwin = target.result.os.tag.isDarwin();

    const lib_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib_mod.linkSystemLibrary("json-c", .{ .preferred_link_mode = .static });
    lib_mod.addConfigHeader(config);
    lib_mod.addCSourceFiles(.{
        .root = b.path("src"),
        .files = &.{
            "logger.c",
            "fcx_request_handler.c",
            "fcx_app.c",
        },
        .flags = &cflags,
    });
    if (is_darwin) {
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
            .flags = &cflags,
        });
    }

    const lib = b.addLibrary(.{
        .name = "FullControlX_s",
        .root_module = lib_mod,
        .linkage = .static,
    });
    b.installArtifact(lib);

    const exe_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    exe_mod.addConfigHeader(config);
    exe_mod.linkLibrary(lib);
    exe_mod.linkSystemLibrary("json-c", .{ .preferred_link_mode = .static });
    if (is_darwin) {
        exe_mod.addCSourceFile(.{ .file = b.path("src/mac/main.m"), .flags = &cflags });
    } else {
        exe_mod.addCSourceFile(.{ .file = b.path("src/main.c"), .flags = &cflags });
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

const cmake_config = .{
    .HAVE_DLFCN_H = 1,
    .HAVE_ENDIAN_H = 1,
    .HAVE_FCNTL_H = 1,
    .HAVE_INTTYPES_H = 1,
    .HAVE_LIMITS_H = 1,
    .HAVE_LOCALE_H = 1,
    .HAVE_MEMORY_H = 1,
    .HAVE_STDARG_H = 1,
    .HAVE_STDINT_H = 1,
    .HAVE_STDLIB_H = 1,
    .HAVE_STRINGS_H = 1,
    .HAVE_STRING_H = 1,
    .HAVE_SYSLOG_H = 1,
    .HAVE_SYS_CDEFS_H = 1,
    .HAVE_SYS_PARAM_H = 1,
    .HAVE_SYS_RANDOM_H = 1,
    .HAVE_SYS_RESOURCE_H = 1,
    .HAVE_SYS_STAT_H = 1,
    .HAVE_SYS_TYPES_H = 1,
    .HAVE_UNISTD_H = 1,
    .HAVE_ATOMIC_BUILTINS = 1,
    .HAVE_DECL_INFINITY = 1,
    .HAVE_DECL_ISINF = 1,
    .HAVE_DECL_ISNAN = 1,
    .HAVE_DECL_NAN = 1,
    .HAVE_OPEN = 1,
    .HAVE_REALLOC = 1,
    .HAVE_SETLOCALE = 1,
    .HAVE_SNPRINTF = 1,
    .HAVE_STRCASECMP = 1,
    .HAVE_STRDUP = 1,
    .HAVE_STRERROR = 1,
    .HAVE_STRNCASECMP = 1,
    .HAVE_USELOCALE = 1,
    .HAVE_VASPRINTF = 1,
    .HAVE_VPRINTF = 1,
    .HAVE_VSNPRINTF = 1,
    .HAVE_VSYSLOG = 1,
    .HAVE_GETRANDOM = 1,
    .HAVE_GETRUSAGE = 1,
    .HAVE_STRTOLL = 1,
    .HAVE_STRTOULL = 1,
    .HAVE___THREAD = 1,
    .JSON_C_HAVE_INTTYPES_H = 1,
    .SIZEOF_INT = @sizeOf(c_int),
    .SIZEOF_INT64_T = @sizeOf(i64),
    .SIZEOF_LONG = @sizeOf(c_long),
    .SIZEOF_LONG_LONG = @sizeOf(c_longlong),
    .SIZEOF_SIZE_T = @sizeOf(usize),
    .SIZEOF_SSIZE_T = @sizeOf(isize),
    .SPEC___THREAD = "__thread",
    .STDC_HEADERS = 1,
};
