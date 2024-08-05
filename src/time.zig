const std = @import("std");

var g: struct {
    gameStart: i64,
    frameStart: i64,
    dt: f32,
} = undefined;

pub fn init() void {
    g.gameStart = std.time.milliTimestamp();
    g.frameStart = g.gameStart;
}

pub fn deinit() void {}

pub fn dt() f32 {
    return g.dt;
}

pub fn gameTime() f32 {
    return @as(f32, @floatFromInt(std.time.milliTimestamp() - g.gameStart)) / 1000.0;
}

pub fn update() void {
    const frameEnd = std.time.milliTimestamp();
    g.dt = @as(f32, @floatFromInt(frameEnd - g.frameStart)) / 1000.0;
    g.frameStart = frameEnd;
}
