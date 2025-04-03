const std = @import("std");
const zjb = @import("zjb");
const alloc = std.heap.wasm_allocator;
const counter_app = @import("counter_app.zig");

pub const panic = zjb.panic;

export fn main() void {
    // Initialize our counter app
    counter_app.init();

    // Verify no memory leaks
    std.debug.assert(zjb.unreleasedHandleCount() == 0);
}
