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

    // DISPLAY
    const display_styles = try zigui.createStyles(zigui.allocator, &.{
        .{ "font-size", "24px" },
        .{ "margin-bottom", "16px" },
    });

    const display = try zigui.div(.{
        .id = "counter-display",
        .style = display_styles,
    }, &[_]zigui.VDom.VNode{
        try zigui.text("Count: {d}", .{count.get()}),
    });

    // BUTTON
    const button_styles = try zigui.createStyles(zigui.allocator, &.{
        .{ "padding", "8px 16px" },
        .{ "background-color", "#0078d7" },
        .{ "color", "white" },
        .{ "border", "none" },
        .{ "border-radius", "4px" },
        .{ "cursor", "pointer" },
    });

    const increment_fn = zjb.fnHandle("handleClick", &increment);
    const button = try zigui.button(.{
        .id = "increment-button",
        .style = button_styles,
        .text = "Increment",
        .onClick = increment_fn,
    });

    // CONTAINER
    const container_styles = try zigui.createStyles(zigui.allocator, &.{
        .{ "display", "flex" },
        .{ "flex-direction", "column" },
        .{ "align-items", "center" },
        .{ "padding", "20px" },
    });

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
