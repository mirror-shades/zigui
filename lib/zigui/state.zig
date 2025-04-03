const std = @import("std");
const zjb = @import("zjb");
const zigui = @import("zigui.zig");
const renderer = @import("renderer.zig");

/// A simple state wrapper that triggers VDOM updates when changed
pub fn LocalState(comptime T: type) type {
    return struct {
        value: T,

        const Self = @This();

        /// Create a new state with an initial value
        pub fn init(initial: T) Self {
            return .{ .value = initial };
        }

        /// Get the current value
        pub fn get(self: *Self) T {
            return self.value;
        }

        /// Set a new value and trigger a VDOM update
        pub fn set(self: *Self, new_value: T) void {
            self.value = new_value;
            renderer.triggerUpdate() catch |err| zjb.throwError(err);
        }
    };
}

/// Create a new local state variable
pub fn useLocal(comptime T: type, initial: T) LocalState(T) {
    return LocalState(T).init(initial);
}

/// A simple global store for application-wide state
pub const Store = struct {
    /// The actual data storage
    data: std.StringHashMap(Value),
    /// Subscribers to state changes
    subscribers: std.ArrayList(Subscriber),
    /// Pending updates to batch
    pending_updates: std.ArrayList([]const u8),

    const Self = @This();

    /// Initialize a new store
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .data = std.StringHashMap(Value).init(allocator),
            .subscribers = std.ArrayList(Subscriber).init(allocator),
            .pending_updates = std.ArrayList([]const u8).init(allocator),
        };
    }

    /// Clean up resources
    pub fn deinit(self: *Self) void {
        var it = self.data.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.data.deinit();
        self.subscribers.deinit();
        self.pending_updates.deinit();
    }

    /// Set a value in the store
    pub fn set(self: *Self, key: []const u8, value: anytype) !void {
        const val = try Value.init(value);
        try self.data.put(key, val);
        try self.notifySubscribers(key);
    }

    /// Get a value from the store
    pub fn get(self: *Self, key: []const u8, comptime T: type) ?T {
        if (self.data.get(key)) |val| {
            return val.as(T);
        }
        return null;
    }

    /// Subscribe to changes for a specific key
    pub fn subscribe(self: *Self, key: ?[]const u8, callback: *const fn ([]const u8) void) !void {
        try self.subscribers.append(.{ .key = key, .callback = callback });
    }

    /// Unsubscribe a callback
    pub fn unsubscribe(self: *Self, callback: *const fn ([]const u8) void) void {
        var i: usize = 0;
        while (i < self.subscribers.items.len) : (i += 1) {
            if (self.subscribers.items[i].callback == callback) {
                _ = self.subscribers.swapRemove(i);
                break;
            }
        }
    }

    fn notifySubscribers(self: *Self, key: []const u8) !void {
        // Add to pending updates if not already there
        for (self.pending_updates.items) |pending_key| {
            if (std.mem.eql(u8, pending_key, key)) {
                return;
            }
        }
        try self.pending_updates.append(key);

        // Schedule a batch update
        try self.scheduleBatchUpdate();
    }

    fn scheduleBatchUpdate(self: *Self) !void {
        // This is a simplified version - in a real implementation, you might use
        // a more sophisticated batching mechanism
        for (self.subscribers.items) |subscriber| {
            if (subscriber.key == null or std.mem.eql(u8, subscriber.key.?, self.pending_updates.items[0])) {
                subscriber.callback(self.pending_updates.items[0]);
            }
        }

        // Clear pending updates
        self.pending_updates.clearRetainingCapacity();

        // Trigger re-render after all subscribers are notified
        try renderer.triggerUpdate();
    }
};

/// Type-safe value storage
const Value = union(enum) {
    Int: i64,
    Float: f64,
    Bool: bool,
    String: []const u8,

    pub fn init(value: anytype) !Value {
        const T = @TypeOf(value);
        return switch (T) {
            i64, i32, i16, i8, u32, u16, u8 => .{ .Int = @intCast(value) },
            f64, f32 => .{ .Float = @floatCast(value) },
            bool => .{ .Bool = value },
            []const u8 => .{ .String = value },
            else => error.UnsupportedType,
        };
    }

    pub fn as(self: Value, comptime T: type) ?T {
        return switch (T) {
            i64, i32, i16, i8, u32, u16, u8 => if (self == .Int) @intCast(self.Int) else null,
            f64, f32 => if (self == .Float) @floatCast(self.Float) else null,
            bool => if (self == .Bool) self.Bool else null,
            []const u8 => if (self == .String) self.String else null,
            else => null,
        };
    }

    pub fn deinit(self: *Value) void {
        // Add cleanup if needed (e.g., for strings allocated from heap)
        _ = self;
    }
};

/// Subscriber to state changes
const Subscriber = struct {
    key: ?[]const u8, // null means subscribe to all changes
    callback: *const fn ([]const u8) void,
};

/// The global store instance
var global_store: ?Store = null;

/// Initialize the state system
pub fn init() !void {
    if (global_store == null) {
        global_store = Store.init(zigui.allocator);
    }
}

/// Clean up the state system
pub fn deinit() void {
    if (global_store) |*store| {
        store.deinit();
        global_store = null;
    }
}

/// Get the store instance
pub fn getStore() *Store {
    return &global_store.?;
}

/// Create a global state value with a custom key
pub fn useGlobal(comptime T: type, key: []const u8, initial: T) !GlobalState(T) {
    // Initialize the store if needed
    if (global_store == null) {
        global_store = Store.init(zigui.allocator);
    }

    // Set initial value in the store
    try getStore().set(key, initial);

    // Create and return the state value
    return GlobalState(T).init(key);
}

/// A state value connected to the global store
pub fn GlobalState(comptime T: type) type {
    return struct {
        key: []const u8,

        const Self = @This();

        /// Create new state with a key and initial value
        pub fn init(key: []const u8) Self {
            return .{ .key = key };
        }

        /// Get current value
        pub fn get(self: *Self) T {
            if (getStore().get(self.key, T)) |value| {
                return value;
            }
            // This should never happen if the state was properly initialized
            @panic("State value not found");
        }

        /// Update value and trigger re-render
        pub fn set(self: *Self, new_value: T) void {
            getStore().set(self.key, new_value) catch |err| zjb.throwError(err);
        }
    };
}
