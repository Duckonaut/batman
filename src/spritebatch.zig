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

        // gather all unique texture handles
        var uniqueTextures = try std.ArrayList(gl.Uint64).initCapacity(alloc, self.items.items.len);
        defer uniqueTextures.deinit();

        for (self.items.items) |item| {
            const found = find: {
                for (uniqueTextures.items) |texture| {
                    if (texture == item.texture.handle) {
                        break :find true;
                    }
                }
                break :find false;
            };

            if (!found) {
                try uniqueTextures.append(item.texture.handle);
            }
        }

        for (uniqueTextures.items) |texture| {
            gl.makeTextureHandleResidentARB(texture);
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

        for (uniqueTextures.items) |texture| {
            gl.makeTextureHandleNonResidentARB(texture);
        }
    }
};

pub fn begin(params: BatchParams) !void {
    if (activeBatch != null) {
        return BatchError.BatchAlreadyActive;
    }

    activeBatch = try Batch.init(params);
}

pub fn draw(texture: *Texture, drawRect: m.Rect, uvRect: m.Rect, color: m.Vec4, depth: f32) !void {
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
    if (activeBatch) |*batch| {
        try batch.flush();

        batch.deinit();
    }

    activeBatch = null;
}
