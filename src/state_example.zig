const std = @import("std");
const zjb = @import("zjb");
const zigui = @import("zigui");

// Local counter state
var localCounter: zigui.State.LocalState(i32) = undefined;

// Global counter state
var globalCounter: zigui.State.GlobalState(i32) = undefined;

// Initialize state variables
fn initState() !void {
    localCounter = zigui.State.useLocal(i32, 0);
    globalCounter = try zigui.State.useGlobal(i32, "global_counter", 0);
}

// Increment local counter
fn incrementLocal() callconv(.C) void {
    localCounter.set(localCounter.get() + 1);
}

// Decrement local counter
fn decrementLocal() callconv(.C) void {
    localCounter.set(localCounter.get() - 1);
}

// Increment global counter
fn incrementGlobal() callconv(.C) void {
    globalCounter.set(globalCounter.get() + 1);
}

// Decrement global counter
fn decrementGlobal() callconv(.C) void {
    globalCounter.set(globalCounter.get() - 1);
}

// Component with local state
fn CounterWithLocalState() anyerror!zigui.VDom.VNode {
    // Create the UI
    const container_styles = try zigui.createStyles(zigui.allocator, &.{
        .{ "display", "flex" },
        .{ "flex-direction", "column" },
        .{ "align-items", "center" },
        .{ "padding", "20px" },
        .{ "margin-bottom", "20px" },
        .{ "border", "1px solid #ccc" },
        .{ "border-radius", "8px" },
    });

    const title_styles = try zigui.createStyles(zigui.allocator, &.{
        .{ "font-size", "18px" },
        .{ "margin-bottom", "10px" },
    });

    const counter_styles = try zigui.createStyles(zigui.allocator, &.{
        .{ "font-size", "24px" },
        .{ "margin-bottom", "16px" },
    });

    const button_container_styles = try zigui.createStyles(zigui.allocator, &.{
        .{ "display", "flex" },
        .{ "gap", "10px" },
    });

    const button_styles = try zigui.createStyles(zigui.allocator, &.{
        .{ "padding", "8px 16px" },
        .{ "background-color", "#0078d7" },
        .{ "color", "white" },
        .{ "border", "none" },
        .{ "border-radius", "4px" },
        .{ "cursor", "pointer" },
    });

    const decrement_button_styles = try zigui.createStyles(zigui.allocator, &.{
        .{ "padding", "8px 16px" },
        .{ "background-color", "#d83b01" },
        .{ "color", "white" },
        .{ "border", "none" },
        .{ "border-radius", "4px" },
        .{ "cursor", "pointer" },
    });

    const increment_local_fn = zjb.fnHandle("incrementLocal", &incrementLocal);
    const decrement_local_fn = zjb.fnHandle("decrementLocal", &decrementLocal);

    return zigui.div(.{
        .class = "local-counter-container",
        .style = container_styles,
    }, &[_]zigui.VDom.VNode{
        try zigui.div(.{
            .style = title_styles,
        }, &[_]zigui.VDom.VNode{
            try zigui.text("Local Counter", .{}),
        }),
        try zigui.div(.{
            .style = counter_styles,
        }, &[_]zigui.VDom.VNode{
            try zigui.text("Count: {d}", .{localCounter.get()}),
        }),
        try zigui.div(.{
            .style = button_container_styles,
        }, &[_]zigui.VDom.VNode{
            try zigui.button(.{
                .style = decrement_button_styles,
                .text = "-",
                .onClick = decrement_local_fn,
            }),
            try zigui.button(.{
                .style = button_styles,
                .text = "+",
                .onClick = increment_local_fn,
            }),
        }),
    });
}

// Component with global state
fn CounterWithGlobalState() anyerror!zigui.VDom.VNode {
    const container_styles = try zigui.createStyles(zigui.allocator, &.{
        .{ "display", "flex" },
        .{ "flex-direction", "column" },
        .{ "align-items", "center" },
        .{ "padding", "20px" },
        .{ "margin-bottom", "20px" },
        .{ "border", "1px solid #ccc" },
        .{ "border-radius", "8px" },
    });

    const title_styles = try zigui.createStyles(zigui.allocator, &.{
        .{ "font-size", "18px" },
        .{ "margin-bottom", "10px" },
    });

    const counter_styles = try zigui.createStyles(zigui.allocator, &.{
        .{ "font-size", "24px" },
        .{ "margin-bottom", "16px" },
    });

    const button_container_styles = try zigui.createStyles(zigui.allocator, &.{
        .{ "display", "flex" },
        .{ "gap", "10px" },
    });

    const button_styles = try zigui.createStyles(zigui.allocator, &.{
        .{ "padding", "8px 16px" },
        .{ "background-color", "#0078d7" },
        .{ "color", "white" },
        .{ "border", "none" },
        .{ "border-radius", "4px" },
        .{ "cursor", "pointer" },
    });

    const decrement_button_styles = try zigui.createStyles(zigui.allocator, &.{
        .{ "padding", "8px 16px" },
        .{ "background-color", "#d83b01" },
        .{ "color", "white" },
        .{ "border", "none" },
        .{ "border-radius", "4px" },
        .{ "cursor", "pointer" },
    });

    const increment_global_fn = zjb.fnHandle("incrementGlobal", &incrementGlobal);
    const decrement_global_fn = zjb.fnHandle("decrementGlobal", &decrementGlobal);

    return zigui.div(.{
        .class = "global-counter-container",
        .style = container_styles,
    }, &[_]zigui.VDom.VNode{
        try zigui.div(.{
            .style = title_styles,
        }, &[_]zigui.VDom.VNode{
            try zigui.text("Global Counter", .{}),
        }),
        try zigui.div(.{
            .style = counter_styles,
        }, &[_]zigui.VDom.VNode{
            try zigui.text("Count: {d}", .{globalCounter.get()}),
        }),
        try zigui.div(.{
            .style = button_container_styles,
        }, &[_]zigui.VDom.VNode{
            try zigui.button(.{
                .style = decrement_button_styles,
                .text = "-",
                .onClick = decrement_global_fn,
            }),
            try zigui.button(.{
                .style = button_styles,
                .text = "+",
                .onClick = increment_global_fn,
            }),
        }),
    });
}

// Main app component
fn App() anyerror!zigui.VDom.VNode {
    const container_styles = try zigui.createStyles(zigui.allocator, &.{
        .{ "display", "flex" },
        .{ "flex-direction", "column" },
        .{ "align-items", "center" },
        .{ "padding", "20px" },
        .{ "max-width", "600px" },
        .{ "margin", "0 auto" },
    });

    const title_styles = try zigui.createStyles(zigui.allocator, &.{
        .{ "font-size", "24px" },
        .{ "margin-bottom", "20px" },
    });

    return zigui.div(.{
        .class = "app-container",
        .style = container_styles,
    }, &[_]zigui.VDom.VNode{
        try zigui.div(.{
            .style = title_styles,
        }, &[_]zigui.VDom.VNode{
            try zigui.text("State Management Example", .{}),
        }),
        try CounterWithLocalState(),
        try CounterWithGlobalState(),
    });
}

// Initialize UI
pub fn init() void {
    // Initialize state first
    initState() catch |err| zjb.throwError(err);

    // Then render the UI
    zigui.render(&App) catch |err| zjb.throwError(err);
}

// Export necessary functions for event handlers
comptime {
    zjb.exportFn("incrementGlobal", &incrementGlobal);
    zjb.exportFn("decrementGlobal", &decrementGlobal);
    zjb.exportFn("incrementLocal", &incrementLocal);
    zjb.exportFn("decrementLocal", &decrementLocal);
}
