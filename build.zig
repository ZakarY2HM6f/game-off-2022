const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardReleaseOptions();
    const target = try std.zig.CrossTarget.parse(.{ .arch_os_abi = "wasm32-freestanding" });

    const emsdk = try std.process.getEnvVarOwned(b.allocator, "EMSDK");
    const em_sysroot = try std.fs.path.resolve(b.allocator, &.{ emsdk, "upstream/emscripten/cache/sysroot" });
    const em_include = try std.fs.path.resolve(b.allocator, &.{ em_sysroot, "include" });

    b.sysroot = em_sysroot;

    const zigmain = b.addStaticLibrary("zigmain", "src/main.zig");
    zigmain.setBuildMode(mode);
    zigmain.setTarget(target);
    zigmain.linkLibC();
    zigmain.addIncludePath(em_include);
    zigmain.install();
}
