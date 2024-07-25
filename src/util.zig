const std = @import("std");

const zopengl = @import("zopengl");
const gl = zopengl.bindings;

var alloc: std.mem.Allocator = undefined;

pub fn init(allocator: std.mem.Allocator) void {
    alloc = allocator;
}

pub fn deinit() void {}

pub fn checkGlError() void {}
