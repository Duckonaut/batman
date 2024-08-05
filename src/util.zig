const std = @import("std");

const zopengl = @import("zopengl");
const gl = zopengl.bindings;

var alloc: std.mem.Allocator = undefined;

pub fn init(allocator: std.mem.Allocator) !void {
    alloc = allocator;
}

pub fn deinit() void {}

const MAX_SIZE = 1024 * 1024;

pub fn readFileToEnd(path: []const u8) ![]const u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const contents = try file.reader().readAllAlloc(alloc, MAX_SIZE);
    return contents;
}

pub fn freeFileData(data: []const u8) void {
    alloc.free(data);
}
