const std = @import("std");
const zjb = @import("zjb");

// Allocator for our virtual DOM
const allocator = std.heap.wasm_allocator;

// State
var count: i32 = 0;

// Virtual DOM node types
const NodeType = enum {
    element,
    text,
};

// Properties for elements
const Props = struct {
    id: ?[]const u8 = null,
    class: ?[]const u8 = null,
    style: ?std.StringHashMap([]const u8) = null,
    // Use event type for better VDOM semantics
    event_type: ?ButtonEventType = null,
    // Add other properties as needed
};

// Event types for buttons
const ButtonEventType = enum {
    increment,
    // Add more event types as needed
};

// Virtual DOM node structure
const VNode = struct {
    node_type: NodeType,
    tag: ?[]const u8 = null, // only for element nodes
    props: Props = .{},
    text: ?[]const u8 = null, // only for text nodes
    children: std.ArrayList(VNode),
    owned_text: bool = false, // Indicates if we need to free the text

    // Create a new element node
    fn createElement(tag: []const u8) !VNode {
        return VNode{
            .node_type = .element,
            .tag = tag,
            .props = .{},
            .text = null,
            .children = std.ArrayList(VNode).init(allocator),
        };
    }

    // Create a new text node
    fn createTextNode(text: []const u8) !VNode {
        return VNode{
            .node_type = .text,
            .tag = null,
            .props = .{},
            .text = text,
            .children = std.ArrayList(VNode).init(allocator),
            .owned_text = false,
        };
    }

    // Create a new text node with owned memory
    fn createOwnedTextNode(text: []const u8) !VNode {
        const owned_text = try allocator.dupe(u8, text);
        return VNode{
            .node_type = .text,
            .tag = null,
            .props = .{},
            .text = owned_text,
            .children = std.ArrayList(VNode).init(allocator),
            .owned_text = true,
        };
    }

    // Add a child node
    fn appendChild(self: *VNode, child: VNode) !void {
        try self.children.append(child);
    }

    // Set an ID property
    fn setId(self: *VNode, id: []const u8) void {
        self.props.id = id;
    }

    // Set a class property
    fn setClass(self: *VNode, class_name: []const u8) void {
        self.props.class = class_name;
    }

    // Set a style property
    fn setStyle(self: *VNode, styles: std.StringHashMap([]const u8)) void {
        self.props.style = styles;
    }

    // Set event type
    fn setEventType(self: *VNode, event_type: ButtonEventType) void {
        self.props.event_type = event_type;
    }

    // Clean up resources
    fn deinit(self: *VNode) void {
        for (self.children.items) |*child| {
            child.deinit();
        }
        if (self.owned_text and self.text != null) {
            allocator.free(self.text.?);
        }
        self.children.deinit();
    }
};

// Current virtual DOM tree
var current_vdom: ?VNode = null;

// Get the current count
pub fn getCount() i32 {
    return count;
}

// Increment the counter and return new value
pub fn increment() i32 {
    count += 1;
    return count;
}

// Handle different button events
fn handleButtonEvent(event_type: ButtonEventType) void {
    switch (event_type) {
        .increment => {
            _ = increment();
            render() catch |err| zjb.throwError(err);
        },
        // Add more event types as needed
    }
}

// Create a button with a specific event type
fn createButton(label: []const u8) !VNode {
    var button = try VNode.createElement("button");

    // Add ID to the button for easier debugging
    button.setId("increment-button");

    var buttonStyles = std.StringHashMap([]const u8).init(allocator);
    try buttonStyles.put("padding", "8px 16px");
    try buttonStyles.put("background-color", "#0078d7");
    try buttonStyles.put("color", "white");
    try buttonStyles.put("border", "none");
    try buttonStyles.put("border-radius", "4px");
    try buttonStyles.put("cursor", "pointer");
    button.setStyle(buttonStyles);

    // Always set this as an increment button
    button.setEventType(.increment);

    const buttonText = try VNode.createTextNode(label);
    try button.appendChild(buttonText);

    return button;
}

// Component function for creating a counter display
fn createCounterDisplay(value: i32) !VNode {
    var display = try VNode.createElement("div");
    display.setId("counter-display");

    var displayStyles = std.StringHashMap([]const u8).init(allocator);
    try displayStyles.put("font-size", "24px");
    try displayStyles.put("margin-bottom", "16px");
    display.setStyle(displayStyles);

    const displayText = try std.fmt.allocPrint(allocator, "Count: {d}", .{value});
    const displayTextNode = VNode{
        .node_type = .text,
        .tag = null,
        .props = .{},
        .text = displayText,
        .children = std.ArrayList(VNode).init(allocator),
        .owned_text = true,
    };
    try display.appendChild(displayTextNode);

    return display;
}

// Create a virtual DOM tree based on current state
fn createVirtualDom() !VNode {
    // Create container div
    var container = try VNode.createElement("div");
    container.setClass("counter-container");

    // Create a styles map
    var containerStyles = std.StringHashMap([]const u8).init(allocator);
    try containerStyles.put("display", "flex");
    try containerStyles.put("flex-direction", "column");
    try containerStyles.put("align-items", "center");
    try containerStyles.put("padding", "20px");
    container.setStyle(containerStyles);

    // Create counter display component
    const display = try createCounterDisplay(count);

    // Create button component with click handler
    const button = try createButton("Increment");

    // Add children to container
    try container.appendChild(display);
    try container.appendChild(button);

    return container;
}

// Render a virtual DOM node to a real DOM element
fn renderNode(vnode: VNode) zjb.Handle {
    const doc = zjb.global("document");

    if (vnode.node_type == .text and vnode.text != null) {
        const text_handle = zjb.string(vnode.text.?);
        defer text_handle.release();
        return doc.call("createTextNode", .{text_handle}, zjb.Handle);
    } else if (vnode.tag != null) {
        const tag_handle = zjb.string(vnode.tag.?);
        defer tag_handle.release();
        const element = doc.call("createElement", .{tag_handle}, zjb.Handle);

        // Set properties
        if (vnode.props.id) |id| {
            const id_handle = zjb.string(id);
            defer id_handle.release();
            element.set("id", id_handle);
        }

        if (vnode.props.class) |class_name| {
            const class_handle = zjb.string(class_name);
            defer class_handle.release();
            element.set("className", class_handle);
        }

        // Set event handlers
        if (vnode.props.event_type) |et| {
            // For simplicity, just use a direct click handler
            if (et == .increment) {
                // Use the simple global handler
                const handler = zjb.fnHandle("handleClick", &handleButtonClick);

                // Add a console log to verify the event handler is being attached
                const console = zjb.global("console");
                console.call("log", .{zjb.constString("Adding click event handler to button")}, void);

                element.call("addEventListener", .{
                    zjb.constString("click"),
                    handler,
                }, void);
            }
        }

        // Apply styles if any
        if (vnode.props.style) |styles| {
            var it = styles.iterator();
            const style = element.get("style", zjb.Handle);
            defer style.release();

            while (it.next()) |entry| {
                const value_handle = zjb.string(entry.value_ptr.*);
                defer value_handle.release();

                // Handle each style property separately with comptime-known field names
                const key = entry.key_ptr.*;
                if (std.mem.eql(u8, key, "display")) {
                    style.set("display", value_handle);
                } else if (std.mem.eql(u8, key, "flex-direction")) {
                    style.set("flexDirection", value_handle);
                } else if (std.mem.eql(u8, key, "align-items")) {
                    style.set("alignItems", value_handle);
                } else if (std.mem.eql(u8, key, "padding")) {
                    style.set("padding", value_handle);
                } else if (std.mem.eql(u8, key, "margin-bottom")) {
                    style.set("marginBottom", value_handle);
                } else if (std.mem.eql(u8, key, "font-size")) {
                    style.set("fontSize", value_handle);
                } else if (std.mem.eql(u8, key, "background-color")) {
                    style.set("backgroundColor", value_handle);
                } else if (std.mem.eql(u8, key, "color")) {
                    style.set("color", value_handle);
                } else if (std.mem.eql(u8, key, "border")) {
                    style.set("border", value_handle);
                } else if (std.mem.eql(u8, key, "border-radius")) {
                    style.set("borderRadius", value_handle);
                } else if (std.mem.eql(u8, key, "cursor")) {
                    style.set("cursor", value_handle);
                }
                // Add more style properties as needed
            }
        }

        // Append children
        for (vnode.children.items) |child| {
            const childEl = renderNode(child);
            defer childEl.release();
            element.call("appendChild", .{childEl}, void);
        }

        return element;
    }

    // Fallback (shouldn't happen)
    return doc.call("createElement", .{zjb.constString("div")}, zjb.Handle);
}

// VDOM diffing algorithm for efficient updates
fn diffAndPatch(old_vdom: VNode, new_vdom: VNode) !void {
    // This is a simple implementation - a real solution would be more complex

    const doc = zjb.global("document");

    // If the node type changed or element tag changed, replace entirely
    if (old_vdom.node_type != new_vdom.node_type or
        (old_vdom.tag != null and new_vdom.tag != null and !std.mem.eql(u8, old_vdom.tag.?, new_vdom.tag.?)))
    {
        // Get the parent element
        const appEl = doc.call("getElementById", .{zjb.constString("app")}, zjb.Handle);
        defer appEl.release();

        // Clear and replace with new node
        const emptyString = zjb.constString("");
        appEl.set("innerHTML", emptyString);

        const newEl = renderNode(new_vdom);
        defer newEl.release();
        appEl.call("appendChild", .{newEl}, void);
        return;
    }

    // Update text content if it's a text node
    if (old_vdom.node_type == .text and new_vdom.node_type == .text) {
        if (old_vdom.text != null and new_vdom.text != null and !std.mem.eql(u8, old_vdom.text.?, new_vdom.text.?)) {
            // We can't directly update text nodes, so we need to find their parent
            const displayEl = doc.call("getElementById", .{zjb.constString("counter-display")}, zjb.Handle);
            defer displayEl.release();

            if (!displayEl.isNull()) {
                const textContent = zjb.string(new_vdom.text.?);
                defer textContent.release();
                displayEl.set("textContent", textContent);
            }
        }
        return;
    }

    // If element node, update properties and children
    if (old_vdom.node_type == .element and new_vdom.node_type == .element) {
        // For simplicity, just update the counter text directly
        // This ensures the display is always in sync with the state
        const displayEl = doc.call("getElementById", .{zjb.constString("counter-display")}, zjb.Handle);
        if (!displayEl.isNull()) {
            defer displayEl.release();
            const newText = try std.fmt.allocPrint(allocator, "Count: {d}", .{count});
            defer allocator.free(newText);

            const textContent = zjb.string(newText);
            defer textContent.release();
            displayEl.set("textContent", textContent);
        }

        // Now process children recursively
        if (old_vdom.children.items.len == new_vdom.children.items.len) {
            for (old_vdom.children.items, new_vdom.children.items, 0..) |*old_child, *new_child, i| {
                // Skip recursion for text nodes within counter display as we've already updated it
                if (old_vdom.props.id != null and std.mem.eql(u8, old_vdom.props.id.?, "counter-display")) {
                    continue;
                }
                _ = i;
                try diffAndPatch(old_child.*, new_child.*);
            }
        } else {
            // If children count changed, just replace the entire content
            // This should only happen during initial render or major UI changes
            if (old_vdom.tag != null and new_vdom.tag != null) {
                const elementId = if (old_vdom.props.id) |id| id else if (new_vdom.props.id) |id| id else null;
                if (elementId) |id| {
                    const el = doc.call("getElementById", .{zjb.string(id)}, zjb.Handle);
                    defer el.release();
                    if (!el.isNull()) {
                        // Clear and replace with new node children
                        const emptyString = zjb.constString("");
                        el.set("innerHTML", emptyString);

                        // Re-add all children
                        for (new_vdom.children.items) |child| {
                            const childEl = renderNode(child);
                            defer childEl.release();
                            el.call("appendChild", .{childEl}, void);
                        }
                    }
                }
            }
        }
    }
}

// Update the DOM based on the current virtual DOM
fn render() !void {
    // Store old vdom for diffing
    const old_vdom = current_vdom;

    // Create new virtual DOM
    current_vdom = try createVirtualDom();

    // If first render, just render everything
    if (old_vdom == null) {
        // Convert to real DOM
        const realDom = renderNode(current_vdom.?);
        defer realDom.release();

        // Clear body and append new content
        const doc = zjb.global("document");
        const body = doc.get("body", zjb.Handle);
        defer body.release();

        // Add container div with ID for future diffing
        const appDiv = doc.call("createElement", .{zjb.constString("div")}, zjb.Handle);
        defer appDiv.release();
        appDiv.set("id", zjb.constString("app"));

        // Clear existing content
        const emptyString = zjb.constString("");
        body.set("innerHTML", emptyString);

        // Add new content
        body.call("appendChild", .{appDiv}, void);
        appDiv.call("appendChild", .{realDom}, void);
    } else {
        // Diff and patch
        try diffAndPatch(old_vdom.?, current_vdom.?);

        // Clean up old tree
        var old_node = old_vdom.?;
        old_node.deinit();
    }

    // No need to add event listener here anymore as it's handled in renderNode
}

// Simpler approach for button events
pub fn handleButtonClick() callconv(.C) void {
    // Log to confirm this function is called
    const console = zjb.global("console");
    console.call("log", .{zjb.constString("Button clicked! Incrementing counter...")}, void);

    // Increment the counter
    _ = increment();

    // Update the UI
    render() catch |err| zjb.throwError(err);
}

// Initialize the counter UI
pub fn init() void {
    render() catch |err| zjb.throwError(err);
}

// Export necessary functions
comptime {
    // Export our button click handler
    zjb.exportFn("handleClick", &handleButtonClick);
}
