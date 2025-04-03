const std = @import("std");
const zjb = @import("zjb");
const zigui = @import("zigui");
const counter_app = @import("counter_app.zig");

export fn main() void {
    zigui.initApp(counter_app);
}
