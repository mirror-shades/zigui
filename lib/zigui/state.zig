const std = @import("std");
const zjb = @import("zjb");
const zigui = @import("zigui.zig");
const renderer = @import("renderer.zig");

/// Holds a reference to a state value
pub fn StateValue(comptime T: type) type {
    return struct {
        value: T,

        const Self = @This();

        /// Create a new state value
        pub fn init(initial_value: T) Self {
            return .{
                .value = initial_value,
            };
        }

        /// Get current value
        pub fn get(self: *Self) T {
            return self.value;
        }

        /// Set a new value and trigger re-render
        pub fn set(self: *Self, new_value: T) void {
            if (self.value != new_value) {
                self.value = new_value;
                // Trigger re-render
                renderer.triggerUpdate() catch |err| zjb.throwError(err);
            }
        }
    };
}

/// State values storage
var state_values = std.ArrayList(anyopaque).init(zigui.allocator);

/// Create a new state hook with initial value
pub fn useState(comptime T: type, initial_value: T) *StateValue(T) {
    const state_ptr = struct {
        var state_value: StateValue(T) = StateValue(T).init(initial_value);
    };

    return &state_ptr.state_value;
}

/// Clean up all state
pub fn deinitState() void {
    for (state_values.items) |ptr| {
        // This is simplified - in a real implementation we'd need
        // type information to properly free each state item
        zigui.allocator.destroy(@ptrCast(ptr));
    }
    state_values.deinit();
}
