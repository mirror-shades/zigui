const std = @import("std");
const zjb = @import("zjb");
const zigui = @import("zigui.zig");

/// Node types in the virtual DOM
pub const NodeType = enum {
    element,
    text,
};

/// Event handler type
pub const EventHandler = zjb.ConstHandle;

/// Event types for UI elements
pub const EventType = enum {
    click,
    change,
    input,
    // Add more as needed
};

/// Properties for elements
pub const Props = struct {
    id: ?[]const u8 = null,
    class: ?[]const u8 = null,
    style: ?std.StringHashMap([]const u8) = null,
    onClick: ?EventHandler = null,
    onChange: ?EventHandler = null,
    onInput: ?EventHandler = null,
    // Add other properties as needed
};

/// VNode structure represents a node in the virtual DOM
pub const VNode = struct {
    node_type: NodeType,
    tag: ?[]const u8 = null, // only for element nodes
    props: Props = .{},
    text: ?[]const u8 = null, // only for text nodes
    children: std.ArrayList(VNode),
    owned_text: bool = false, // Indicates if we need to free the text

    /// Create a new element node
    pub fn createElement(tag: []const u8, props: Props) !VNode {
        return VNode{
            .node_type = .element,
            .tag = tag,
            .props = props,
            .text = null,
            .children = std.ArrayList(VNode).init(zigui.allocator),
        };
    }

    /// Create a new text node
    pub fn createTextNode(text: []const u8) !VNode {
        return VNode{
            .node_type = .text,
            .tag = null,
            .props = .{},
            .text = text,
            .children = std.ArrayList(VNode).init(zigui.allocator),
            .owned_text = false,
        };
    }

    /// Create a new text node with owned memory
    pub fn createOwnedTextNode(text: []const u8) !VNode {
        const owned_text = try zigui.allocator.dupe(u8, text);
        return VNode{
            .node_type = .text,
            .tag = null,
            .props = .{},
            .text = owned_text,
            .children = std.ArrayList(VNode).init(zigui.allocator),
            .owned_text = true,
        };
    }

    /// Add a child node
    pub fn appendChild(self: *VNode, child: VNode) !void {
        try self.children.append(child);
    }

    /// Clean up resources
    pub fn deinit(self: *VNode) void {
        for (self.children.items) |*child| {
            child.deinit();
        }
        if (self.owned_text and self.text != null) {
            zigui.allocator.free(self.text.?);
        }
        if (self.props.style) |*style| {
            style.deinit();
        }
        self.children.deinit();
    }
};

/// Component type definition
pub const Component = *const fn () anyerror!VNode;
