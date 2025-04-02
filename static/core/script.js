const env = {
  memory: new WebAssembly.Memory({ initial: 1 }),
  __stack_pointer: 0,
};

var zjb = new Zjb();

// Add a function to manually trigger the handleClick
function testHandleClick() {
  console.log("Manually triggering handleClick");
  if (zjb.exports.handleClick) {
    zjb.exports.handleClick();
    console.log("handleClick was called manually");
  } else {
    console.error("handleClick is not available");
  }
}

(function () {
  WebAssembly.instantiateStreaming(fetch("source.wasm"), {
    env: env,
    zjb: zjb.imports,
  }).then(function (results) {
    zjb.setInstance(results.instance);
    results.instance.exports.main();

    // Add debugging to check if handleClick is properly exported
    console.log(
      "Checking if handleClick is exported:",
      zjb.exports.handleClick
    );

    // Add a global click listener to the document to debug click events
    document.addEventListener("click", function (e) {
      console.log("Document click detected on:", e.target);
      if (e.target.tagName === "BUTTON") {
        console.log("Button was clicked!");

        // Try calling the handleClick function directly
        testHandleClick();

        // If we have specific button ID
        if (e.target.id === "increment-button") {
          console.log("Increment button clicked specifically");
        }
      }
    });

    console.log("reading zjb global from zig", zjb.exports.checkTestVar());
    console.log("reading zjb global from javascript", zjb.exports.test_var);

    console.log("writing zjb global from zig", zjb.exports.setTestVar());
    console.log("reading zjb global from zig", zjb.exports.checkTestVar());
    console.log("reading zjb global from javascript", zjb.exports.test_var);

    console.log(
      "writing zjb global from javascript",
      (zjb.exports.test_var = 80.8)
    );
    console.log("reading zjb global from zig", zjb.exports.checkTestVar());
    console.log("reading zjb global from javascript", zjb.exports.test_var);

    console.log(
      "calling zjb exports from javascript",
      zjb.exports.incrementAndGet(1)
    );
    console.log(
      "calling zjb exports from javascript",
      zjb.exports.incrementAndGet(1)
    );
    console.log(
      "calling zjb exports from javascript",
      zjb.exports.incrementAndGet(1)
    );
  });
})();
