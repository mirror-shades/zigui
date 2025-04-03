const std = @import("std");
const zjb = @import("zjb");
const zigui = @import("zigui.zig");
const VDom = @import("vdom.zig");

/// Props for div element
pub const DivProps = struct {
    id: ?[]const u8 = null,
    class: ?[]const u8 = null,
    style: ?std.StringHashMap([]const u8) = null,
};

/// Props for button element
pub const ButtonProps = struct {
    id: ?[]const u8 = null,
    class: ?[]const u8 = null,
    style: ?std.StringHashMap([]const u8) = null,
    text: []const u8,
    onClick: ?VDom.EventHandler = null,
};

/// Create a div element
pub fn div(props: DivProps, children: []const VDom.VNode) !VDom.VNode {
    var node = try VDom.VNode.createElement("div", .{
        .id = props.id,
        .class = props.class,
        .style = props.style,
    });

    for (children) |child| {
        try node.appendChild(child);
    }

    return node;
}

/// Create a button element
pub fn button(props: ButtonProps) !VDom.VNode {
    var node = try VDom.VNode.createElement("button", .{
        .id = props.id,
        .class = props.class,
        .style = props.style,
        .onClick = props.onClick,
    });

    const text_node = try VDom.VNode.createTextNode(props.text);
    try node.appendChild(text_node);

    return node;
}

/// Create a text node with format
pub fn text(comptime fmt: []const u8, args: anytype) !VDom.VNode {
    const text_content = try std.fmt.allocPrint(zigui.allocator, fmt, args);
    return VDom.VNode{
        .node_type = .text,
        .tag = null,
        .props = .{},
        .text = text_content,
        .children = std.ArrayList(VDom.VNode).init(zigui.allocator),
        .owned_text = true,
    };
}
