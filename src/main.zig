const std = @import("std");
const zjb = @import("zjb");
const alloc = std.heap.wasm_allocator;
const site = @import("site.zig");

fn log(v: anytype) void {
    zjb.global("console").call("log", .{v}, void);
}
fn logStr(str: []const u8) void {
    const handle = zjb.string(str);
    defer handle.release();
    zjb.global("console").call("log", .{handle}, void);
}

pub const panic = zjb.panic;
export fn main() void {
    // Initialize our site
    site.init();

    // Verify no memory leaks
    std.debug.assert(zjb.unreleasedHandleCount() == 0);
}

fn keydownCallback(event: zjb.Handle) callconv(.C) void {
    defer event.release();

    zjb.global("console").call("log", .{ zjb.constString("From keydown callback, event:"), event }, void);
}

var value: i32 = 0;
fn incrementAndGet(increment: i32) callconv(.C) i32 {
    value += increment;
    return value;
}

var test_var: f32 = 1337.7331;
fn checkTestVar() callconv(.C) f32 {
    return test_var;
}

fn setTestVar() callconv(.C) f32 {
    test_var = 42.24;
    return test_var;
}

comptime {
    zjb.exportFn("incrementAndGet", &incrementAndGet);

    zjb.exportGlobal("test_var", &test_var);
    zjb.exportFn("checkTestVar", &checkTestVar);
    zjb.exportFn("setTestVar", &setTestVar);
}
