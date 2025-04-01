const env = {
  memory: new WebAssembly.Memory({ initial: 1 }),
  __stack_pointer: 0,
};

var zjb = new Zjb();

// Function to load and initialize WASM
async function loadAndInitWasm() {
  try {
    const results = await WebAssembly.instantiateStreaming(
      fetch("source.wasm"),
      { env: env, zjb: zjb.imports }
    );
    zjb.setInstance(results.instance);
    results.instance.exports.main();

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
  } catch (error) {
    console.error("Error loading WASM:", error);
  }
}

// Initial load
loadAndInitWasm();

let lastModified = Date.now();

setInterval(async () => {
  try {
    const response = await fetch("source.wasm", { method: "HEAD" });
    const currentModified = new Date(
      response.headers.get("last-modified")
    ).getTime();

    if (currentModified > lastModified) {
      console.log("WASM file changed, reloading...");
      lastModified = currentModified;
      location.reload();
    }
  } catch (error) {
    console.error("Error checking for updates:", error);
  }
}, 1000); // Check every second
