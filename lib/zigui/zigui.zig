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
pub const useState = State.useState;

// Re-export render
pub const render = @import("renderer.zig").render;

// Standard allocator for the framework
pub const allocator = std.heap.wasm_allocator;
