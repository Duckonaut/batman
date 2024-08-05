const std = @import("std");

const zaudio = @import("zaudio");

var alloc: std.mem.Allocator = undefined;

var g: struct {
    engine: *zaudio.Engine,
} = undefined;

pub fn init(allocator: std.mem.Allocator) !void {
    alloc = allocator;

    zaudio.init(alloc);

    g.engine = try zaudio.Engine.create(null);
}

pub fn deinit() void {
    g.engine.destroy();
    zaudio.deinit();
}
