const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create and export the zjb module
    const zjb_mod = b.addModule("zjb", .{
        .root_source_file = b.path("zjb.zig"),
    });

    // Create the generate_js executable
    const generate_js = b.addExecutable(.{
        .name = "generate_js",
        .root_source_file = b.path("generate_js.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Make both the module and executable available to dependent packages
    b.installArtifact(generate_js);

    // Export public artifacts and modules
    const bridge_mod = b.addModule("javascript_bridge", .{
        .root_source_file = b.path("zjb.zig"),
    });
    bridge_mod.addImport("zjb", zjb_mod);
}
