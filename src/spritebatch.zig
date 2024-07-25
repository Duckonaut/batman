const std = @import("std");

const zopengl = @import("zopengl");
const gl = zopengl.bindings;
const zgui = @import("zgui");

const Texture = @import("texture.zig").Texture;
const Shader = @import("shader.zig").Shader;

const m = @import("math.zig");

var alloc: std.mem.Allocator = undefined;
var activeBatch: ?Batch = null;

var batchGlobals: struct {
    quadVBO: gl.Uint,
    quadVAO: gl.Uint,
    defaultShader: Shader,
    naiveShader: Shader,
    naive: bool = false,

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

    const naive_vs_file = try std.fs.cwd().openFile("content/sb_bindful_vs.glsl", .{});
    defer naive_vs_file.close();

    const naive_fs_file = try std.fs.cwd().openFile("content/sb_bindful_fs.glsl", .{});
    defer naive_fs_file.close();

    const naive_vs = try naive_vs_file.readToEndAlloc(alloc, 4096);
    defer alloc.free(naive_vs);
    const naive_fs = try naive_fs_file.readToEndAlloc(alloc, 4096);
    defer alloc.free(naive_fs);

    batchGlobals.naiveShader = try Shader.fromSource(naive_vs, naive_fs);

    gl.genBuffers(1, &batchGlobals.vertexSSBO);
    gl.bindBuffer(gl.SHADER_STORAGE_BUFFER, batchGlobals.vertexSSBO);
    gl.bufferData(gl.SHADER_STORAGE_BUFFER, 0, null, gl.DYNAMIC_DRAW);

    gl.genBuffers(1, &batchGlobals.fragmentSSBO);
    gl.bindBuffer(gl.SHADER_STORAGE_BUFFER, batchGlobals.fragmentSSBO);
    gl.bufferData(gl.SHADER_STORAGE_BUFFER, 0, null, gl.DYNAMIC_DRAW);
}

pub fn deinit() void {}

pub fn toggleNaive() void {
    batchGlobals.naive = !batchGlobals.naive;
}

pub fn isNaive() bool {
    return batchGlobals.naive;
}

const BatchItem = struct {
    texture: *Texture,
    drawRect: m.Rect,
    uvRect: m.Rect,
    color: m.Vec4,
    depth: f32,
};

pub const BatchError = error{
    BatchAlreadyActive,
};

pub const BatchParams = struct {
    initialCapacity: usize = 16,
    projection: m.Mat4 = m.Mat4.identity,
};

pub const Batch = struct {
    items: std.ArrayList(BatchItem),
    params: BatchParams,

    const SpriteVertexData = packed struct {
        rect: m.Vec4,
    };

    const SpriteDrawData = packed struct {
        texture: gl.Uint64,
        _padding: u64 = undefined,
        uvRect: m.Vec4,
        color: m.Vec4,
    };

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
        }

        gl.bufferData(gl.SHADER_STORAGE_BUFFER, @intCast(@sizeOf(SpriteVertexData) * self.items.items.len), @ptrCast(vertexData), gl.DYNAMIC_DRAW);

        gl.bindBufferBase(gl.SHADER_STORAGE_BUFFER, 0, batchGlobals.vertexSSBO);

        gl.bindBuffer(gl.SHADER_STORAGE_BUFFER, batchGlobals.fragmentSSBO);

        const fragmentData = try alloc.alloc(SpriteDrawData, self.items.items.len);
        defer alloc.free(fragmentData);

        for (self.items.items, 0..) |item, i| {
            fragmentData[i].texture = item.texture.handle;
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
    if (batchGlobals.naive) {
        gl.useProgram(batchGlobals.naiveShader.id);
        batchGlobals.naiveShader.setUniformMat4("u_projection", params.projection);
        return;
    }
    if (activeBatch != null) {
        return BatchError.BatchAlreadyActive;
    }

    activeBatch = try Batch.init(params);
}

pub fn draw(texture: *Texture, drawRect: m.Rect, uvRect: m.Rect, color: m.Vec4, depth: f32) !void {
    if (batchGlobals.naive) {
        gl.bindTexture(gl.TEXTURE_2D, texture.id);
        batchGlobals.naiveShader.setUniformVec4("u_rect", m.Vec4.new(drawRect.pos.x, drawRect.pos.y, drawRect.size.x, drawRect.size.y));
        batchGlobals.naiveShader.setUniformVec4("u_uvRect", m.Vec4.new(uvRect.pos.x, uvRect.pos.y, uvRect.size.x, uvRect.size.y));
        batchGlobals.naiveShader.setUniformVec4("u_color", color);

        gl.bindVertexArray(batchGlobals.quadVAO);
        gl.drawArrays(gl.TRIANGLES, 0, 6);
    }

    if (activeBatch) |*batch| {
        try batch.items.append(BatchItem{
            .texture = texture,
            .drawRect = drawRect,
            .uvRect = uvRect,
            .color = color,
            .depth = depth,
        });
    }
}

pub fn end() !void {
    if (batchGlobals.naive) {
        return;
    }
    if (activeBatch) |*batch| {
        try batch.flush();

        batch.deinit();
    }

    activeBatch = null;
}
