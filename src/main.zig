const std = @import("std");

const zgui = @import("zgui");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;

const zstbi = @import("zstbi");

const audio = @import("audio.zig");
const sb = @import("spritebatch.zig");
const shader = @import("shader.zig");
const gfx = @import("gfx.zig");
const m = @import("math.zig");
const util = @import("util.zig");
const time = @import("time.zig");

const Texture = gfx.Texture;

const content_dir = @import("build_options").content_dir;
const window_title = "greachermania";

var gpa: std.mem.Allocator = undefined;

var screen_width: i32 = 512;
var screen_height: i32 = 512;
fn sizeCallback(_: *glfw.Window, width: i32, height: i32) callconv(.C) void {
    screen_width = width;
    screen_height = height;
    gl.viewport(0, 0, width, height);
}

fn keyboardCallback(_: *glfw.Window, key: glfw.Key, _: i32, action: glfw.Action, _: glfw.Mods) callconv(.C) void {
    if (action == glfw.Action.press and key == glfw.Key.space) {}
}

fn openglDebugCallback(_: gl.Enum, t: gl.Enum, _: gl.Uint, _: gl.Enum, length: gl.Sizei, message: [*c]const gl.Char, _: *const anyopaque) callconv(.C) void {
    if (t == gl.DEBUG_TYPE_ERROR or t == gl.DEBUG_TYPE_UNDEFINED_BEHAVIOR) {
        std.debug.print("GLMSG: {s}\n", .{message[0..@intCast(length)]});
    }
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

    const window = try glfw.Window.create(screen_width, screen_height, window_title, null);
    defer window.destroy();
    window.setSizeLimits(screen_width, screen_height, -1, -1);

    _ = window.setSizeCallback(sizeCallback);
    _ = window.setKeyCallback(keyboardCallback);

    glfw.makeContextCurrent(window);
    glfw.swapInterval(1);

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

    try audio.init(gpa);
    defer audio.deinit();

    gfx.init(gpa);
    defer gfx.deinit();

    shader.init(gpa);
    defer shader.deinit();

    try sb.init(gpa);
    defer sb.deinit();

    try util.init(gpa);
    defer util.deinit();

    time.init();
    defer time.deinit();

    try init();
    defer destroy();

    while (!window.shouldClose() and window.getKey(.escape) != .press) {
        glfw.pollEvents();
        time.update();

        zgui.backend.newFrame(@intCast(screen_width), @intCast(screen_height));

        try update();

        try draw();

        zgui.backend.draw();

        window.swapBuffers();
    }
}

const State = struct {
    textures: std.StringHashMap(Texture),
    gameTarget: gfx.RenderTarget,
    rand: std.rand.DefaultPrng,
};

var state: State = undefined;

const textureNames: [1][]const u8 = .{
    "player",
};

fn init() !void {
    const prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    state.rand = prng;
    state.textures = std.StringHashMap(Texture).init(gpa);

    for (textureNames) |name| {
        const path = try std.fmt.allocPrint(gpa, "{s}textures/{s}.png", .{ content_dir, name });
        defer gpa.free(path);
        const t = try Texture.fromFile(path);
        try state.textures.put(name, t);
    }

    state.gameTarget = try gfx.RenderTarget.fromSize(64, 64);
}

fn destroy() void {
    var iter = state.textures.iterator();
    while (iter.next()) |entry| {
        Texture.destroy(entry.value_ptr);
    }
    state.textures.deinit();
    state.gameTarget.destroy();
}

fn update() !void {
    _ = zgui.begin("textures", .{});

    var iter = state.textures.iterator();

    _ = zgui.beginTable("textures_table", .{
        .column = 2,
        .flags = .{
            .borders = zgui.TableBorderFlags.all,
            .resizable = false,
            .sizing = .fixed_fit,
        },
    });
    zgui.tableSetupColumn("id", .{
        .flags = .{
            .width_fixed = true,
        },
    });
    zgui.tableSetupColumn("texture", .{});
    zgui.tableHeadersRow();
    zgui.tableNextRow(.{});

    while (iter.next()) |entry| {
        const t = entry.value_ptr;
        const name = entry.key_ptr.*;
        const tag = try std.fmt.allocPrintZ(gpa, "##{s}", .{name});
        defer gpa.free(tag);
        _ = zgui.tableNextColumn();
        zgui.text("{d}", .{t.id});
        _ = zgui.tableNextColumn();
        zgui.image(
            @ptrFromInt(t.id),
            .{
                .w = 64,
                .h = 64,
            },
        );
        if (zgui.isItemHovered(.{}) and zgui.beginTooltip()) {
            zgui.text("{s}", .{name});
            zgui.indent(.{ .indent_w = 8.0 });
            zgui.text("id: {d}", .{t.id});
            zgui.text("size: {d}x{d}", .{ t.width, t.height });
            zgui.text("handle: {d}", .{t.handle});
            zgui.unindent(.{ .indent_w = 8.0 });
            zgui.endTooltip();
        }
        zgui.tableNextRow(.{});
    }

    zgui.endTable();

    zgui.end();
}

fn draw() !void {
    gl.enable(gl.BLEND);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    gl.clear(gl.COLOR_BUFFER_BIT);

    state.gameTarget.set();
    gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 0.05, 0.1, 0.2, 1.0 });

    const proj = m.Mat4.createOrthogonal(0, 64, 0, 64, -1, 1);

    try sb.begin(.{ .projection = proj });

    const texture = state.textures.getPtr("player") orelse return error.Unavailable;
    try sb.draw(
        texture,
        m.rect(28, 28, 40, 40),
        time.gameTime(),
        null,
        null,
        null,
        0.0,
    );

    try sb.end();
    gfx.RenderTarget.unset();
    gl.viewport(0, 0, screen_width, screen_height);

    gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 0.0, 0.0, 0.0, 1.0 });

    try sb.begin(.{});

    var viewRect = m.rect(0.0, 0.0, 1.0, 1.0);
    const aspect: f32 = @as(f32, @floatFromInt(screen_width)) / @as(f32, @floatFromInt(screen_height));
    if (aspect > 1.0) {
        viewRect.size.x = 1.0 / aspect;
        viewRect.pos.x = (1.0 - viewRect.size.x) / 2.0;
    } else {
        viewRect.size.y = aspect;
        viewRect.pos.y = (1.0 - viewRect.size.y) / 2.0;
    }

    try sb.drawHandle(
        state.gameTarget.handle,
        viewRect,
        0.0,
        null,
        m.vec2(0.0, 0.0),
        null,
        0.0,
    );

    try sb.end();
}
