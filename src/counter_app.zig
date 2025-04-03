const std = @import("std");
const zjb = @import("zjb");
const zigui = @import("zigui");

// State declaration
var count = zigui.useState(i32, 0);

// Increment function
fn increment() callconv(.C) void {
    count.set(count.get() + 1);
}

// Main counter component
fn Counter() anyerror!zigui.VDom.VNode {
    // Define some styles
    var container_styles = std.StringHashMap([]const u8).init(zigui.allocator);
    try container_styles.put("display", "flex");
    try container_styles.put("flex-direction", "column");
    try container_styles.put("align-items", "center");
    try container_styles.put("padding", "20px");

    var display_styles = std.StringHashMap([]const u8).init(zigui.allocator);
    try display_styles.put("font-size", "24px");
    try display_styles.put("margin-bottom", "16px");

    var button_styles = std.StringHashMap([]const u8).init(zigui.allocator);
    try button_styles.put("padding", "8px 16px");
    try button_styles.put("background-color", "#0078d7");
    try button_styles.put("color", "white");
    try button_styles.put("border", "none");
    try button_styles.put("border-radius", "4px");
    try button_styles.put("cursor", "pointer");

    // Create display node
    const display = try zigui.div(.{
        .id = "counter-display",
        .style = display_styles,
    }, &[_]zigui.VDom.VNode{
        try zigui.text("Count: {d}", .{count.get()}),
    });

    // Create button node
    const increment_fn = zjb.fnHandle("handleClick", &increment);
    const button = try zigui.button(.{
        .id = "increment-button",
        .style = button_styles,
        .text = "Increment",
        .onClick = increment_fn,
    });

    // Container with children
    return zigui.div(.{
        .class = "counter-container",
        .style = container_styles,
    }, &[_]zigui.VDom.VNode{
        display,
        button,
    });
}

// Initialize UI
pub fn init() void {
    zigui.render(&Counter) catch |err| zjb.throwError(err);
}

// Export necessary functions for event handlers
comptime {
    zjb.exportFn("handleClick", &increment);
}
