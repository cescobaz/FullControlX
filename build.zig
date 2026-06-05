const std = @import("std");

// Root build orchestrator. Replaces the old build_and_run.sh:
//   zig build       -> build fcxd + mix deps.get + mix compile
//   zig build run   -> the above, then start the Phoenix server
//
// fcxd is a C/Objective-C driver built natively by Zig (path dependency).
// The web app keeps using elixir/mix as its own build tool; we just orchestrate.
pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    // Forward optimize only -- NOT target -- so fcxd's own default_target
    // (darwin 10.11 deployment, see fcxd/build.zig) still applies.
    const fcxd = b.dependency("fcxd", .{ .optimize = optimize });
    b.installArtifact(fcxd.artifact("FullControlX")); // -> zig-out/bin/FullControlX

    // mix steps run in fcx-web. has_side_effects keeps them from being cached
    // away by Zig and lets stdout/stderr pass through (QR code, live server).
    const web = b.path("fcx-web");

    const deps_get = b.addSystemCommand(&.{ "mix", "deps.get" });
    deps_get.setCwd(web);
    deps_get.has_side_effects = true;

    const compile = b.addSystemCommand(&.{ "mix", "compile" });
    compile.setCwd(web);
    compile.has_side_effects = true;
    compile.step.dependOn(&deps_get.step);

    // Default `zig build` = build fcxd + mix compile.
    b.getInstallStep().dependOn(&compile.step);

    // `zig build run` = default build, then start the Phoenix server. The
    // server spawns fcxd at runtime from zig-out/bin, so it must depend on the
    // install step that puts the binary there.
    const server = b.addSystemCommand(&.{ "mix", "phx.server" });
    server.setCwd(web);
    server.has_side_effects = true;
    server.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Build everything and start the Phoenix server");
    run_step.dependOn(&server.step);
}
