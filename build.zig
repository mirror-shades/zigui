const std = @import("std");
const demo_webserver = @import("demo_webserver");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    // Add an option for dev mode
    const dev_mode = b.option(
        bool,
        "dev",
        "Use development static files",
    ) orelse false;

    const zjb = b.dependency("javascript_bridge", .{});

    const source = b.addExecutable(.{
        .name = "source",
        .root_source_file = b.path("src/main.zig"),
        .target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .freestanding }),
        .optimize = optimize,
    });
    source.root_module.addImport("zjb", zjb.module("zjb"));
    source.entry = .disabled;
    source.rdynamic = true;

    const extract_source = b.addRunArtifact(zjb.artifact("generate_js"));
    const extract_source_out = extract_source.addOutputFileArg("zjb_extract.js");
    extract_source.addArg("Zjb"); // Name of js class.
    extract_source.addArtifactArg(source);

    const dir = std.Build.InstallDir.prefix;
    b.getInstallStep().dependOn(&b.addInstallArtifact(source, .{
        .dest_dir = .{ .override = dir },
    }).step);
    b.getInstallStep().dependOn(&b.addInstallFileWithDir(extract_source_out, dir, "zjb_extract.js").step);
    b.getInstallStep().dependOn(&b.addInstallDirectory(.{
        .source_dir = b.path(if (dev_mode) "static/dev" else "static/prod"),
        .install_dir = dir,
        .install_subdir = "",
    }).step);

    const run_demo_server = demo_webserver.runDemoServer(b, b.getInstallStep(), .{});
    const serve = b.step("serve", "serve website locally");
    serve.dependOn(run_demo_server);
}
