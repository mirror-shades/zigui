const std = @import("std");
const zjb = @import("zjb");

// Re-export components
pub const Components = @import("components.zig");
pub const State = @import("state.zig");
pub const VDom = @import("vdom.zig");

// Re-export component functions
pub const div = Components.div;
pub const button = Components.button;
pub const text = Components.text;

// Re-export state management
pub const useState = State.useLocal;
pub const createState = State.useGlobal;
pub const getStore = State.getStore;

// Re-export render
pub const render = @import("renderer.zig").render;

// Standard allocator for the framework
pub const allocator = std.heap.wasm_allocator;

// Logging utilities
pub fn log(v: anytype) void {
    zjb.global("console").call("log", .{v}, void);
}

pub fn logStr(str: []const u8) void {
    const handle = zjb.string(str);
    defer handle.release();
    zjb.global("console").call("log", .{handle}, void);
}

// Standard panic handler
pub const panic = zjb.panic;

// Main application initialization
pub fn initApp(comptime app: anytype) void {
    // Initialize the app
    app.init();

    // Verify no memory leaks
    std.debug.assert(zjb.unreleasedHandleCount() == 0);
}

pub fn createStyles(style_allocator: std.mem.Allocator, styles: []const struct { []const u8, []const u8 }) !std.StringHashMap([]const u8) {
    var style_map = std.StringHashMap([]const u8).init(style_allocator);
    errdefer style_map.deinit();

    for (styles) |style| {
        const key = style[0];
        const value = style[1];
        try style_map.put(key, value);
    }

    return style_map;
}
