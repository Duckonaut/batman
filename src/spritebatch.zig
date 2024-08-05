const std = @import("std");

const zopengl = @import("zopengl");
const gl = zopengl.bindings;
const zgui = @import("zgui");

const Texture = @import("gfx.zig").Texture;
const Shader = @import("shader.zig").Shader;

const m = @import("math.zig");

var alloc: std.mem.Allocator = undefined;
var activeBatch: ?Batch = null;

var batchGlobals: struct {
    quadVBO: gl.Uint,
    quadVAO: gl.Uint,
    defaultShader: Shader,

    vertexSSBO: gl.Uint,
    fragmentSSBO: gl.Uint,
} = undefined;

const QuadVertex = struct {
    pos: m.Vec2,
};

const quadVertices = [6]QuadVertex{
    .{ .pos = m.Vec2.new(0.0, 0.0) },
    .{ .pos = m.Vec2.new(1.0, 0.0) },
    .{ .pos = m.Vec2.new(1.0, 1.0) },
    .{ .pos = m.Vec2.new(1.0, 1.0) },
    .{ .pos = m.Vec2.new(0.0, 1.0) },
    .{ .pos = m.Vec2.new(0.0, 0.0) },
};

pub fn init(allocator: std.mem.Allocator) !void {
    alloc = allocator;

    gl.genVertexArrays(1, &batchGlobals.quadVAO);
    gl.bindVertexArray(batchGlobals.quadVAO);

    gl.genBuffers(1, &batchGlobals.quadVBO);
    gl.bindBuffer(gl.ARRAY_BUFFER, batchGlobals.quadVBO);
    gl.bufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(quadVertices)), &quadVertices, gl.STATIC_DRAW);

    gl.enableVertexAttribArray(0);
    gl.vertexAttribPointer(0, 2, gl.FLOAT, 0, @sizeOf(QuadVertex), @ptrFromInt(0));

    const vs_file = try std.fs.cwd().openFile("content/sb_vs.glsl", .{});
    defer vs_file.close();

    const fs_file = try std.fs.cwd().openFile("content/sb_fs.glsl", .{});
    defer fs_file.close();

    const vs = try vs_file.readToEndAlloc(alloc, 4096);
    defer alloc.free(vs);
    const fs = try fs_file.readToEndAlloc(alloc, 4096);
    defer alloc.free(fs);

    batchGlobals.defaultShader = try Shader.fromSource(vs, fs);

    gl.genBuffers(1, &batchGlobals.vertexSSBO);
    gl.bindBuffer(gl.SHADER_STORAGE_BUFFER, batchGlobals.vertexSSBO);
    gl.bufferData(gl.SHADER_STORAGE_BUFFER, 0, null, gl.DYNAMIC_DRAW);

    gl.genBuffers(1, &batchGlobals.fragmentSSBO);
    gl.bindBuffer(gl.SHADER_STORAGE_BUFFER, batchGlobals.fragmentSSBO);
    gl.bufferData(gl.SHADER_STORAGE_BUFFER, 0, null, gl.DYNAMIC_DRAW);
}

pub fn deinit() void {}

const BatchItem = struct {
    texture: gl.Uint64,
    drawRect: m.Rect,
    rotation: f32,
    uvRect: m.Rect,
    origin: m.Vec2,
    color: m.Vec4,
    depth: f32,
};

pub const BatchError = error{
    BatchAlreadyActive,
};

pub const BatchParams = struct {
    initialCapacity: usize = 16,
    projection: m.Mat4 = m.Mat4.createOrthogonal(0.0, 1.0, 1.0, 0.0, -1, 1),
};

pub const Batch = struct {
    items: std.ArrayList(BatchItem),
    extraFragData: std.ArrayList(u8),
    extraVertData: std.ArrayList(u8),
    params: BatchParams,

    pub fn init(params: BatchParams) !Batch {
        var batch: Batch = undefined;
        batch.items = try std.ArrayList(BatchItem).initCapacity(alloc, params.initialCapacity);
        batch.params = params;
        return batch;
    }

    pub fn deinit(self: *Batch) void {
        self.items.deinit();
    }

    pub fn flush(self: *Batch) !void {
        if (self.items.items.len == 0) {
            return;
        }

        batchGlobals.defaultShader.use();
        batchGlobals.defaultShader.setUniformMat4("u_projection", self.params.projection);

        gl.bindVertexArray(batchGlobals.quadVAO);

        gl.enable(gl.BLEND);
        gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

        gl.bindBuffer(gl.SHADER_STORAGE_BUFFER, batchGlobals.vertexSSBO);

        const vertexData = try alloc.alloc(SpriteVertexData, self.items.items.len);
        defer alloc.free(vertexData);

        for (self.items.items, 0..) |item, i| {
            vertexData[i].rect = m.Vec4.new(
                item.drawRect.pos.x,
                item.drawRect.pos.y,
                item.drawRect.size.x,
                item.drawRect.size.y,
            );
            vertexData[i].origin = item.origin;
            vertexData[i].rotation = item.rotation;
        }

        gl.bufferData(gl.SHADER_STORAGE_BUFFER, @intCast(@sizeOf(SpriteVertexData) * self.items.items.len), @ptrCast(vertexData), gl.DYNAMIC_DRAW);

        gl.bindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, batchGlobals.vertexSSBO);

        gl.bindBuffer(gl.SHADER_STORAGE_BUFFER, batchGlobals.fragmentSSBO);

        const fragmentData = try alloc.alloc(SpriteDrawData, self.items.items.len);
        defer alloc.free(fragmentData);

        for (self.items.items, 0..) |item, i| {
            fragmentData[i].texture = item.texture;
            fragmentData[i].uvRect = m.Vec4.new(
                item.uvRect.pos.x,
                item.uvRect.pos.y,
                item.uvRect.size.x,
                item.uvRect.size.y,
            );
            fragmentData[i].color = item.color;
        }

        gl.bufferData(gl.SHADER_STORAGE_BUFFER, @intCast(@sizeOf(SpriteDrawData) * self.items.items.len), @ptrCast(fragmentData), gl.DYNAMIC_DRAW);

        gl.bindBufferBase(gl.SHADER_STORAGE_BUFFER, 1, batchGlobals.fragmentSSBO);

        gl.drawArraysInstanced(gl.TRIANGLES, 0, 6, @intCast(self.items.items.len));
    }
};

pub fn begin(params: BatchParams) !void {
    if (activeBatch != null) {
        return BatchError.BatchAlreadyActive;
    }

    activeBatch = try Batch.init(params);
}

pub fn drawExt(
    texture: *Texture,
    drawRect: m.Rect,
    rotation: f32,
    uvRect: ?m.Rect,
    origin: ?m.Vec2,
    color: ?m.Vec4,
    depth: f32,
    ExtraVertType: type,
    extraVert: ExtraVertType,
    ExtraFragType: type,
    extraFrag: ExtraFragType,
) !void {
    return drawExt(
        texture.handle,
        drawRect,
        rotation,
        uvRect,
        origin,
        color,
        depth,
        ExtraVertType,
        extraVert,
        ExtraFragType,
        extraFrag,
    );
}

pub fn drawFull(
    texture: gl.Uint64,
    drawRect: m.Rect,
    rotation: f32,
    uvRect: ?m.Rect,
    origin: ?m.Vec2,
    color: ?m.Vec4,
    depth: f32,
    extraVert: ?*anyopaque,
    extraFrag: ?*anyopaque,
) !void {
    if (activeBatch) |*batch| {
        try batch.items.append(BatchItem{
            .texture = texture,
            .drawRect = drawRect,
            .rotation = rotation,
            .uvRect = uvRect orelse m.Rect.new(0.0, 0.0, 1.0, 1.0),
            .origin = origin orelse m.Vec2.new(0.5, 0.5),
            .color = color orelse m.Vec4.new(1.0, 1.0, 1.0, 1.0),
            .depth = depth,
        });

        if (extraVert) |extra| {
            const vertDataSlice: []u8 = @ptrCast(extra);
            try batch.extraVertData.appendSlice(vertDataSlice[0..extraVertSize]);
        }

        if (extraFrag) |extra| {
            const fragDataSlice: []u8 = @ptrCast(extra);
            try batch.extraFragData.appendSlice(fragDataSlice[0..extraFragSize]);
        }
    }
}

pub fn end() !void {
    if (activeBatch) |*batch| {
        try batch.flush();

        batch.deinit();
    }

    activeBatch = null;
}

pub const BatchShader = struct {
    const SpriteVertexData = packed struct {
        rect: m.Vec4,
        origin: m.Vec2 = m.Vec2.new(0.5, 0.5),
        rotation: f32 = 0.0,
        _padding: f32 = 0.0,
    };

    const SpriteDrawData = packed struct {
        texture: gl.Uint64,
        _padding: u64 = undefined,
        uvRect: m.Vec4,
        color: m.Vec4,
    };

    const Self = @This();

    shader: Shader,

    pub fn init(vertexShader: []const u8, fragmentShader: []const u8, vertex) !Self {
        var self: Self = undefined;
        self.shader = try Shader.fromSource(vertexShader, fragmentShader);

        return self;
    }

    pub fn deinit(self: *Self) void {
        self.shader.deinit();
    }

    pub fn setUniformMat4(self: *Self, name: [:0]const u8, value: m.Mat4) void {
        self.shader.setUniformMat4(name, value);
    }

    pub fn setUniformFloat(self: *Self, name: [:0]const u8, value: f32) void {
        self.shader.setUniformFloat(name, value);
    }

    pub fn setUniformVec2(self: *Self, name: [:0]const u8, value: m.Vec2) void {
        self.shader.setUniformVec2(name, value);
    }

    pub fn setUniformVec3(self: *Self, name: [:0]const u8, value: m.Vec3) void {
        self.shader.setUniformVec3(name, value);
    }

    pub fn setUniformVec4(self: *Self, name: [:0]const u8, value: m.Vec4) void {
        self.shader.setUniformVec4(name, value);
    }

    pub fn setUniformTexture(self: *Self, name: [:0]const u8, texture: *Texture) void {
        self.shader.setUniformTexture(name, texture);
    }
};
