pub const packages = struct {
    pub const @"12209083b0c43d0f68a26a48a7b26ad9f93b22c9cff710c78ddfebb47b89cfb9c7a4" = struct {
        pub const build_root = "C:\\Users\\User\\AppData\\Local\\zig\\p\\mime-2.0.1-AAAAAIQgAACQg7DEPQ9oompIp7Jq2fk7IsnP9xDHjd_r";
        pub const build_zig = @import("12209083b0c43d0f68a26a48a7b26ad9f93b22c9cff710c78ddfebb47b89cfb9c7a4");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
        };
    };
    pub const @"demo_webserver-0.0.0-s8bjD7sqAACqVmz3kvf2iJbe0Jk9Hv6SBKz-kVlZ7q0J" = struct {
        pub const build_root = "C:\\Users\\User\\AppData\\Local\\zig\\p\\demo_webserver-0.0.0-s8bjD7sqAACqVmz3kvf2iJbe0Jk9Hv6SBKz-kVlZ7q0J";
        pub const build_zig = @import("demo_webserver-0.0.0-s8bjD7sqAACqVmz3kvf2iJbe0Jk9Hv6SBKz-kVlZ7q0J");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "mime", "12209083b0c43d0f68a26a48a7b26ad9f93b22c9cff710c78ddfebb47b89cfb9c7a4" },
        };
    };
    pub const javascript_bridge = struct {
        pub const build_root = "C:\\dev\\zig\\zig-web\\javascript_bridge";
        pub const build_zig = @import("javascript_bridge");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "javascript_bridge", "javascript_bridge" },
    .{ "demo_webserver", "demo_webserver-0.0.0-s8bjD7sqAACqVmz3kvf2iJbe0Jk9Hv6SBKz-kVlZ7q0J" },
};
