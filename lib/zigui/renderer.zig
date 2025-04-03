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

const CommonCssProperties = std.ComptimeStringMap([]const u8, .{
    // Layout
    .{ "display", "display" },
    .{ "position", "position" },
    .{ "width", "width" },
    .{ "height", "height" },
    .{ "min-width", "minWidth" },
    .{ "min-height", "minHeight" },
    .{ "max-width", "maxWidth" },
    .{ "max-height", "maxHeight" },
    .{ "box-sizing", "boxSizing" },

    // Positioning
    .{ "top", "top" },
    .{ "right", "right" },
    .{ "bottom", "bottom" },
    .{ "left", "left" },
    .{ "z-index", "zIndex" },
    .{ "float", "float" },
    .{ "clear", "clear" },

    // Margin & Padding
    .{ "margin", "margin" },
    .{ "margin-top", "marginTop" },
    .{ "margin-right", "marginRight" },
    .{ "margin-bottom", "marginBottom" },
    .{ "margin-left", "marginLeft" },
    .{ "margin-inline", "marginInline" },
    .{ "margin-inline-start", "marginInlineStart" },
    .{ "margin-inline-end", "marginInlineEnd" },
    .{ "margin-block", "marginBlock" },
    .{ "margin-block-start", "marginBlockStart" },
    .{ "margin-block-end", "marginBlockEnd" },

    .{ "padding", "padding" },
    .{ "padding-top", "paddingTop" },
    .{ "padding-right", "paddingRight" },
    .{ "padding-bottom", "paddingBottom" },
    .{ "padding-left", "paddingLeft" },
    .{ "padding-inline", "paddingInline" },
    .{ "padding-inline-start", "paddingInlineStart" },
    .{ "padding-inline-end", "paddingInlineEnd" },
    .{ "padding-block", "paddingBlock" },
    .{ "padding-block-start", "paddingBlockStart" },
    .{ "padding-block-end", "paddingBlockEnd" },

    // Flexbox
    .{ "flex", "flex" },
    .{ "flex-direction", "flexDirection" },
    .{ "flex-wrap", "flexWrap" },
    .{ "flex-flow", "flexFlow" },
    .{ "flex-grow", "flexGrow" },
    .{ "flex-shrink", "flexShrink" },
    .{ "flex-basis", "flexBasis" },
    .{ "justify-content", "justifyContent" },
    .{ "align-items", "alignItems" },
    .{ "align-self", "alignSelf" },
    .{ "align-content", "alignContent" },
    .{ "gap", "gap" },
    .{ "row-gap", "rowGap" },
    .{ "column-gap", "columnGap" },
    .{ "order", "order" },

    // Grid
    .{ "grid", "grid" },
    .{ "grid-template", "gridTemplate" },
    .{ "grid-template-columns", "gridTemplateColumns" },
    .{ "grid-template-rows", "gridTemplateRows" },
    .{ "grid-template-areas", "gridTemplateAreas" },
    .{ "grid-auto-columns", "gridAutoColumns" },
    .{ "grid-auto-rows", "gridAutoRows" },
    .{ "grid-auto-flow", "gridAutoFlow" },
    .{ "grid-column", "gridColumn" },
    .{ "grid-column-start", "gridColumnStart" },
    .{ "grid-column-end", "gridColumnEnd" },
    .{ "grid-row", "gridRow" },
    .{ "grid-row-start", "gridRowStart" },
    .{ "grid-row-end", "gridRowEnd" },
    .{ "grid-area", "gridArea" },

    // Colors & Backgrounds
    .{ "color", "color" },
    .{ "background", "background" },
    .{ "background-color", "backgroundColor" },
    .{ "background-image", "backgroundImage" },
    .{ "background-repeat", "backgroundRepeat" },
    .{ "background-position", "backgroundPosition" },
    .{ "background-size", "backgroundSize" },
    .{ "background-attachment", "backgroundAttachment" },
    .{ "background-clip", "backgroundClip" },
    .{ "background-origin", "backgroundOrigin" },
    .{ "background-blend-mode", "backgroundBlendMode" },
    .{ "opacity", "opacity" },

    // Border & Outline
    .{ "border", "border" },
    .{ "border-width", "borderWidth" },
    .{ "border-style", "borderStyle" },
    .{ "border-color", "borderColor" },
    .{ "border-top", "borderTop" },
    .{ "border-right", "borderRight" },
    .{ "border-bottom", "borderBottom" },
    .{ "border-left", "borderLeft" },
    .{ "border-radius", "borderRadius" },
    .{ "border-top-left-radius", "borderTopLeftRadius" },
    .{ "border-top-right-radius", "borderTopRightRadius" },
    .{ "border-bottom-right-radius", "borderBottomRightRadius" },
    .{ "border-bottom-left-radius", "borderBottomLeftRadius" },
    .{ "border-collapse", "borderCollapse" },
    .{ "border-spacing", "borderSpacing" },
    .{ "outline", "outline" },
    .{ "outline-width", "outlineWidth" },
    .{ "outline-style", "outlineStyle" },
    .{ "outline-color", "outlineColor" },
    .{ "outline-offset", "outlineOffset" },

    // Typography
    .{ "font", "font" },
    .{ "font-family", "fontFamily" },
    .{ "font-size", "fontSize" },
    .{ "font-weight", "fontWeight" },
    .{ "font-style", "fontStyle" },
    .{ "font-variant", "fontVariant" },
    .{ "font-stretch", "fontStretch" },
    .{ "line-height", "lineHeight" },
    .{ "letter-spacing", "letterSpacing" },
    .{ "word-spacing", "wordSpacing" },
    .{ "text-align", "textAlign" },
    .{ "text-decoration", "textDecoration" },
    .{ "text-decoration-line", "textDecorationLine" },
    .{ "text-decoration-style", "textDecorationStyle" },
    .{ "text-decoration-color", "textDecorationColor" },
    .{ "text-transform", "textTransform" },
    .{ "text-indent", "textIndent" },
    .{ "text-overflow", "textOverflow" },
    .{ "text-shadow", "textShadow" },
    .{ "white-space", "whiteSpace" },
    .{ "word-break", "wordBreak" },
    .{ "word-wrap", "wordWrap" },
    .{ "overflow-wrap", "overflowWrap" },

    // Effects & Animations
    .{ "transform", "transform" },
    .{ "transform-origin", "transformOrigin" },
    .{ "transform-style", "transformStyle" },
    .{ "backface-visibility", "backfaceVisibility" },
    .{ "perspective", "perspective" },
    .{ "perspective-origin", "perspectiveOrigin" },
    .{ "transition", "transition" },
    .{ "transition-property", "transitionProperty" },
    .{ "transition-duration", "transitionDuration" },
    .{ "transition-timing-function", "transitionTimingFunction" },
    .{ "transition-delay", "transitionDelay" },
    .{ "animation", "animation" },
    .{ "animation-name", "animationName" },
    .{ "animation-duration", "animationDuration" },
    .{ "animation-timing-function", "animationTimingFunction" },
    .{ "animation-delay", "animationDelay" },
    .{ "animation-iteration-count", "animationIterationCount" },
    .{ "animation-direction", "animationDirection" },
    .{ "animation-fill-mode", "animationFillMode" },
    .{ "animation-play-state", "animationPlayState" },

    // Box Effects
    .{ "box-shadow", "boxShadow" },
    .{ "box-decoration-break", "boxDecorationBreak" },
    .{ "filter", "filter" },
    .{ "backdrop-filter", "backdropFilter" },
    .{ "mix-blend-mode", "mixBlendMode" },
    .{ "isolation", "isolation" },

    // Overflow & Visibility
    .{ "overflow", "overflow" },
    .{ "overflow-x", "overflowX" },
    .{ "overflow-y", "overflowY" },
    .{ "visibility", "visibility" },
    .{ "clip", "clip" },
    .{ "clip-path", "clipPath" },
    .{ "mask", "mask" },

    // Cursor & Interaction
    .{ "cursor", "cursor" },
    .{ "pointer-events", "pointerEvents" },
    .{ "user-select", "userSelect" },
    .{ "resize", "resize" },
    .{ "touch-action", "touchAction" },

    // Table
    .{ "table-layout", "tableLayout" },
    .{ "caption-side", "captionSide" },
    .{ "empty-cells", "emptyCells" },

    // Lists
    .{ "list-style", "listStyle" },
    .{ "list-style-type", "listStyleType" },
    .{ "list-style-position", "listStylePosition" },
    .{ "list-style-image", "listStyleImage" },

    // Content
    .{ "content", "content" },
    .{ "quotes", "quotes" },
    .{ "counter-reset", "counterReset" },
    .{ "counter-increment", "counterIncrement" },

    // Writing Modes
    .{ "writing-mode", "writingMode" },
    .{ "text-orientation", "textOrientation" },
    .{ "direction", "direction" },
    .{ "unicode-bidi", "unicodeBidi" },
});

const StyleSystem = struct {
    const CSSError = error{
        InvalidProperty,
        InvalidValue,
    };

    pub fn setStyle(element: zjb.Handle, property: []const u8, value: []const u8) !void {
        // Try fast path first
        if (CommonCssProperties.get(property)) |js_name| {
            const value_handle = zjb.string(value);
            defer value_handle.release();
            element.style.set(js_name, value_handle);
            return;
        }

        // Validate property name for dynamic path
        if (!isValidCSSProperty(property)) {
            return CSSError.InvalidProperty;
        }

        // Fall back to dynamic approach for uncommon properties
        try setDynamicStyle(element, property, value);
    }

    fn setDynamicStyle(element: zjb.Handle, property: []const u8, value: []const u8) !void {
        const camelCase = try toCamelCase(zigui.allocator, property);
        defer zigui.allocator.free(camelCase);

        // Use JavaScript's style object directly
        const js = try std.fmt.allocPrint(zigui.allocator, "this.style['{s}'] = '{s}'", .{ camelCase, value });
        defer zigui.allocator.free(js);

        const code_handle = zjb.string(js);
        defer code_handle.release();

        zjb.global("Function")
            .new(.{code_handle})
            .call("call", .{element}, void);
    }

    fn isValidCSSProperty(property: []const u8) bool {
        // Basic validation:
        // - Must start with a letter or hyphen
        // - Can only contain letters, numbers, and hyphens
        // - Cannot have consecutive hyphens
        if (property.len == 0) return false;

        var last_was_hyphen = false;
        for (property, 0..) |c, i| {
            switch (c) {
                'a'...'z', 'A'...'Z' => last_was_hyphen = false,
                '0'...'9' => {
                    if (i == 0) return false;
                    last_was_hyphen = false;
                },
                '-' => {
                    if (last_was_hyphen) return false;
                    last_was_hyphen = true;
                },
                else => return false,
            }
        }
        return !last_was_hyphen;
    }

    fn toCamelCase(allocator: std.mem.Allocator, kebab: []const u8) ![]const u8 {
        var result = std.ArrayList(u8).init(allocator);
        errdefer result.deinit();

        var capitalize_next = false;
        for (kebab, 0..) |c, i| {
            if (c == '-') {
                capitalize_next = true;
                continue;
            }

            if (capitalize_next) {
                try result.append(std.ascii.toUpper(c));
                capitalize_next = false;
            } else if (i == 0) {
                try result.append(std.ascii.toLower(c));
            } else {
                try result.append(c);
            }
        }

        return result.toOwnedSlice();
    }
};
