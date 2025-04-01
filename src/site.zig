const std = @import("std");
const zjb = @import("zjb");

// State
var count: i32 = 0;

// Get the current count
pub fn getCount() i32 {
    return count;
}

// Increment the counter and return new value
pub fn increment() i32 {
    count += 1;
    return count;
}

// Update the display
fn updateDisplay() void {
    const countStr = std.fmt.allocPrint(std.heap.wasm_allocator, "Count: {d}", .{count}) catch |e| zjb.throwError(e);
    defer std.heap.wasm_allocator.free(countStr);

    const displayElement = zjb.global("document")
        .call("getElementById", .{zjb.constString("counter-display")}, zjb.Handle);
    defer displayElement.release();

    const textContent = zjb.string(countStr);
    defer textContent.release();

    displayElement.set("textContent", textContent);
}

// Callback for button click
fn handleClick() callconv(.C) void {
    _ = increment();
    updateDisplay();
}

// Initialize the counter UI
pub fn init() void {
    // Create initial HTML elements
    const doc = zjb.global("document");

    // Create container div
    const container = doc.call("createElement", .{zjb.constString("div")}, zjb.Handle);
    defer container.release();

    // Create display element
    const display = doc.call("createElement", .{zjb.constString("div")}, zjb.Handle);
    defer display.release();
    display.set("id", zjb.constString("counter-display"));

    // Create button
    const button = doc.call("createElement", .{zjb.constString("button")}, zjb.Handle);
    defer button.release();
    button.set("textContent", zjb.constString("Increment th"));

    // Add click handler to button
    const handler = zjb.fnHandle("handleCounterClick", &handleClick);
    button.call("addEventListener", .{
        zjb.constString("click"),
        handler,
    }, void);

    // Append elements
    container.call("appendChild", .{display}, void);
    container.call("appendChild", .{button}, void);

    // Add to document body
    const body = doc.get("body", zjb.Handle);
    defer body.release();
    body.call("appendChild", .{container}, void);

    // Initialize display
    updateDisplay();
}

// Export necessary functions
comptime {
    _ = handleClick; // Reference the function to ensure it's not optimized away
}
