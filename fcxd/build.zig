const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const cflags = [_][]const u8{
        "-std=c99",
        // "-pedantic",
        // "-Werror",
        // "-Wall",
    };

    const config = b.addConfigHeader(.{
        .style = .{ .cmake = b.path("src/fullcontrol_x_config.h.in") },
        .include_path = "src/fullcontrol_x_config.h",
    }, cmake_config);

    const lib = b.addStaticLibrary(.{
        .name = "FullControlX_s",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        // .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib.linkSystemLibrary2("json-c", .{ .preferred_link_mode = .static });
    lib.addConfigHeader(config);
    lib.addCSourceFiles(.{
        .root = b.path("src"),
        .files = &.{
            "logger.c",
            "fcx_request_handler.c",
            "fcx_app.c",
        },
        .flags = &cflags,
    });
    if (target.result.isDarwin()) {
        lib.linkFramework("CoreFoundation");
        lib.linkFramework("CoreGraphics");
        lib.linkFramework("AppKit");
        lib.linkFramework("IOKit");
        lib.linkFramework("Carbon");
        lib.addCSourceFiles(.{
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

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "FullControlX",
        .target = target,
        .optimize = optimize,
    });
    exe.addConfigHeader(config);
    exe.linkLibrary(lib);
    exe.linkSystemLibrary2("json-c", .{ .preferred_link_mode = .static });
    if (target.result.isDarwin()) {
        exe.addCSourceFile(.{ .file = b.path("src/mac/main.m") });
    } else {
        exe.addCSourceFile(.{ .file = b.path("src/main.c") });
    }

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
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
