import subprocess
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import multiprocessing
import shutil
import os


def run_server():
    subprocess.run(["python", "-m", "http.server", "-d", "zig-out"])

def build():
    print("building...")
    # Initial build
    subprocess.run(["zig", "build"], check=True)
    # delete the old script.js
    os.remove("zig-out/script.js")
    # copy the new script.js
    shutil.copy("static/dev/dev-script.js", "zig-out/script.js")
    print("built")

def update_wasm():
    subprocess.run(["zig", "build", "-Dupdate=true"], check=True)

class UpdateHandler(FileSystemEventHandler):
    def __init__(self):
        self.last_build = 0
        self.build_cooldown = 1  # seconds

    def on_modified(self, event):
        # Ignore non-file events and files not in src directory
        if event.is_directory or not event.src_path.startswith('src'):
            return
            
        # Prevent multiple builds within cooldown period
        current_time = time.time()
        if current_time - self.last_build < self.build_cooldown:
            return
            
        print(f"\nDetected change in {event.src_path}")
        try:
            update_wasm()

        except subprocess.CalledProcessError as e:
            print(f"Build failed: {e}")
        
        self.last_build = current_time


def main():
    build()
    # Start HTTP server in a separate process
    server_process = multiprocessing.Process(target=run_server)
    server_process.start()
    
    # Set up file watching
    event_handler = UpdateHandler()
    observer = Observer()
    observer.schedule(event_handler, path='src', recursive=True)
    observer.start()
    
    print("\nWatching for changes in src directory...")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        print("\nStopping server...")
        server_process.terminate()
    observer.join()
    server_process.join()

if __name__ == "__main__":
    main()