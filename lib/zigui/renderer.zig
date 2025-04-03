const std = @import("std");
const zjb = @import("zjb");
const zigui = @import("zigui.zig");
const VDom = @import("vdom.zig");

/// Current virtual DOM tree
var current_vdom: ?VDom.VNode = null;

/// Root component to render
var root_component: ?VDom.Component = null;

/// Render a virtual DOM node to a real DOM element
fn renderNode(vnode: VDom.VNode) zjb.Handle {
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
        if (vnode.props.onClick) |handler| {
            // Register with the event system
            const event_type_handle = zjb.constString("click");
            element.call("addEventListener", .{
                event_type_handle,
                handler,
            }, void);
        }

        if (vnode.props.onChange) |handler| {
            // Register with the event system
            const event_type_handle = zjb.constString("change");
            element.call("addEventListener", .{
                event_type_handle,
                handler,
            }, void);
        }

        if (vnode.props.onInput) |handler| {
            // Register with the event system
            const event_type_handle = zjb.constString("input");
            element.call("addEventListener", .{
                event_type_handle,
                handler,
            }, void);
        }

        // Apply styles if any
        if (vnode.props.style) |styles| {
            var it = styles.iterator();
            const style = element.get("style", zjb.Handle);
            defer style.release();

            while (it.next()) |entry| {
                const value_handle = zjb.string(entry.value_ptr.*);
                defer value_handle.release();

                const key = entry.key_ptr.*;

                // We need to use specific style property names because zjb.set requires comptime-known field names
                // A small set of common CSS properties for demonstration
                if (std.mem.eql(u8, key, "display")) {
                    style.set("display", value_handle);
                } else if (std.mem.eql(u8, key, "flex-direction")) {
                    style.set("flexDirection", value_handle);
                } else if (std.mem.eql(u8, key, "align-items")) {
                    style.set("alignItems", value_handle);
                } else if (std.mem.eql(u8, key, "padding")) {
                    style.set("padding", value_handle);
                } else if (std.mem.eql(u8, key, "margin")) {
                    style.set("margin", value_handle);
                } else if (std.mem.eql(u8, key, "margin-bottom")) {
                    style.set("marginBottom", value_handle);
                } else if (std.mem.eql(u8, key, "font-size")) {
                    style.set("fontSize", value_handle);
                } else if (std.mem.eql(u8, key, "color")) {
                    style.set("color", value_handle);
                } else if (std.mem.eql(u8, key, "background-color")) {
                    style.set("backgroundColor", value_handle);
                } else if (std.mem.eql(u8, key, "border")) {
                    style.set("border", value_handle);
                } else if (std.mem.eql(u8, key, "border-radius")) {
                    style.set("borderRadius", value_handle);
                } else if (std.mem.eql(u8, key, "cursor")) {
                    style.set("cursor", value_handle);
                }
                // Add more styles as needed
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

/// VDOM diffing algorithm for efficient updates
fn diffAndPatch(old_vdom: VDom.VNode, new_vdom: VDom.VNode) !void {
    // This is a simplified version - a real solution would be more complex

    const doc = zjb.global("document");

    // If the node type changed or element tag changed, replace entirely
    if (old_vdom.node_type != new_vdom.node_type or
        (old_vdom.tag != null and new_vdom.tag != null and !std.mem.eql(u8, old_vdom.tag.?, new_vdom.tag.?)))
    {
        // Get the root element
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

    // For simplicity, just replace the entire DOM
    // A real implementation would do proper diffing here
    const appEl = doc.call("getElementById", .{zjb.constString("app")}, zjb.Handle);
    defer appEl.release();

    // Clear and replace with new node
    const emptyString = zjb.constString("");
    appEl.set("innerHTML", emptyString);

    const newEl = renderNode(new_vdom);
    defer newEl.release();
    appEl.call("appendChild", .{newEl}, void);
}

/// Initialize the UI with a root component
pub fn render(component: VDom.Component) !void {
    root_component = component;
    try triggerUpdate();
}

/// Update the DOM based on the current virtual DOM
pub fn triggerUpdate() !void {
    if (root_component) |comp| {
        // Store old vdom for diffing
        const old_vdom = current_vdom;

        // Create new virtual DOM
        current_vdom = try comp();

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
    }
}

/// Clean up before exit
pub fn deinit() void {
    if (current_vdom) |*vdom| {
        vdom.deinit();
        current_vdom = null;
    }
}
