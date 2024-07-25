const std = @import("std");

const zgui = @import("zgui");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;

const zstbi = @import("zstbi");

const sb = @import("spritebatch.zig");
const shader = @import("shader.zig");
const texture = @import("texture.zig");
const m = @import("math.zig");

const Texture = texture.Texture;

const content_dir = @import("build_options").content_dir;
const window_title = "dev: batman";

var gpa: std.mem.Allocator = undefined;

var screen_width: i32 = 800;
var screen_height: i32 = 500;
fn sizeCallback(_: *glfw.Window, width: i32, height: i32) callconv(.C) void {
    screen_width = width;
    screen_height = height;
    gl.viewport(0, 0, width, height);
}

fn keyboardCallback(_: *glfw.Window, key: glfw.Key, _: i32, action: glfw.Action, _: glfw.Mods) callconv(.C) void {
    if (action == glfw.Action.press and key == glfw.Key.space) {
        sb.toggleNaive();
        std.debug.print("Naive: {s}\n", .{if (sb.isNaive()) "true" else "false"});
    }
}

fn openglDebugCallback(_: gl.Enum, t: gl.Enum, _: gl.Uint, _: gl.Enum, length: gl.Sizei, message: [*c]const gl.Char, _: *const anyopaque) callconv(.C) void {
    if (t == gl.DEBUG_TYPE_ERROR) {
        std.debug.print("GLERR: ", .{});
    } else {
        return;
    }

    std.debug.print("{s}\n", .{message[0..@intCast(length)]});
}

const FRAME_TIME_SAMPLES = 2000;

var frametimeSamples: [FRAME_TIME_SAMPLES]i64 = undefined;
var frametimeSampleIndex: usize = 0;
var frametimeSampleCount: usize = 0;

pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_state.deinit();
    gpa = gpa_state.allocator();

    try glfw.init();
    defer glfw.terminate();

    // Change current working directory to where the executable is located.
    {
        var buffer: [1024]u8 = undefined;
        const path = std.fs.selfExeDirPath(buffer[0..]) catch ".";
        std.posix.chdir(path) catch {};
    }

    const gl_major = 4;
    const gl_minor = 3;
    glfw.windowHintTyped(.context_version_major, gl_major);
    glfw.windowHintTyped(.context_version_minor, gl_minor);
    glfw.windowHintTyped(.opengl_profile, .opengl_core_profile);
    glfw.windowHintTyped(.opengl_forward_compat, true);
    glfw.windowHintTyped(.client_api, .opengl_api);
    glfw.windowHintTyped(.doublebuffer, true);

    const window = try glfw.Window.create(800, 500, window_title, null);
    defer window.destroy();
    window.setSizeLimits(400, 400, -1, -1);

    _ = window.setSizeCallback(sizeCallback);
    _ = window.setKeyCallback(keyboardCallback);

    glfw.makeContextCurrent(window);
    glfw.swapInterval(0);

    try zopengl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor);
    try zopengl.loadExtension(glfw.getProcAddress, .ARB_bindless_texture);
    gl.enable(gl.DEBUG_OUTPUT);
    gl.debugMessageCallback(openglDebugCallback, null);

    zgui.init(gpa);
    defer zgui.deinit();

    const scale_factor = scale_factor: {
        const scale = window.getContentScale();
        break :scale_factor @max(scale[0], scale[1]);
    };

    zgui.getStyle().scaleAllSizes(scale_factor);

    zgui.backend.init(window);
    defer zgui.backend.deinit();

    zstbi.init(gpa);
    defer zstbi.deinit();

    texture.init(gpa);
    defer texture.deinit();

    shader.init(gpa);
    defer shader.deinit();

    try sb.init(gpa);
    defer sb.deinit();

    try init();
    defer destroy();

    var frames: u64 = 0;
    var startTime = std.time.milliTimestamp();

    while (!window.shouldClose() and window.getKey(.escape) != .press) {
        glfw.pollEvents();

        zgui.backend.newFrame(@intCast(screen_width), @intCast(screen_height));

        try draw();

        zgui.backend.draw();

        frames += 1;
        const currentTime = std.time.milliTimestamp();
        if (currentTime - startTime >= 1000) {
            std.debug.print("FPS: {d}\n", .{frames});

            startTime += 1000;
            frames = 0;
        }

        window.swapBuffers();
    }
}

const State = struct {
    textures: std.ArrayList(Texture),
    rand: std.rand.DefaultPrng,
};

var state: State = undefined;

fn init() !void {
    const prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    state.rand = prng;
    state.textures = std.ArrayList(Texture).init(gpa);

    for (0..1024) |_| {
        var col1: [3]u8 = undefined;
        var col2: [3]u8 = undefined;
        state.rand.fill(col1[0..]);
        state.rand.fill(col2[0..]);

        const data = [16]u8{
            col1[0], col1[1], col1[2], 255,
            col2[0], col2[1], col2[2], 255,
            col2[0], col2[1], col2[2], 255,
            col1[0], col1[1], col1[2], 255,
        };

        const t = try Texture.fromRaw(2, 2, &data);
        try state.textures.append(t);

        gl.makeTextureHandleResidentARB(t.handle);
    }

    std.debug.print("Textures: {d}\n", .{state.textures.items.len});
}

fn destroy() void {
    for (state.textures.items) |*t| {
        gl.makeTextureHandleNonResidentARB(t.handle);
        t.destroy();
    }
    state.textures.deinit();
}

fn draw() !void {
    gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 0, 0, 0, 1.0 });

    const proj = m.Mat4.createOrthogonal(0, @floatFromInt(screen_width), @floatFromInt(screen_height), 0, -1, 1);

    const texSize = m.Vec2.splat(8.0);
    const texPadding = m.Vec2.splat(2.0);

    const spritesX: usize = @intCast(@divTrunc(screen_width, @as(i32, @intFromFloat(texSize.x + texPadding.x))));
    const spritesY: usize = @intCast(@divTrunc(screen_height, @as(i32, @intFromFloat(texSize.y + texPadding.y))));

    const spriteCount: usize = spritesX * spritesY;

    try sb.begin(.{ .projection = proj });

    for (0..spriteCount) |i| {
        const textureIndex = state.rand.next() % state.textures.items.len;

        const t = &state.textures.items[textureIndex];
        const pos = m.Vec2{
            .x = texPadding.x + @as(f32, @floatFromInt(i % spritesX)) * (texPadding.x + texSize.x),
            .y = texPadding.y + @as(f32, @floatFromInt(i / spritesX)) * (texPadding.y + texSize.y),
        };

        try sb.draw(t, m.Rect{
            .pos = pos,
            .size = texSize,
        }, m.Rect.one(), m.Vec4.one(), 0.0);
    }

    try sb.end();
}
