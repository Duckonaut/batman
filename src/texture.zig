const std = @import("std");

const zopengl = @import("zopengl");
const gl = zopengl.bindings;

const zstbi = @import("zstbi");

var samp: gl.Uint = undefined;
var alloc: std.mem.Allocator = undefined;

pub fn init(allocator: std.mem.Allocator) void {
    gl.genSamplers(1, &samp);
    gl.bindSampler(0, samp);
    gl.samplerParameteri(samp, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.samplerParameteri(samp, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.samplerParameteri(samp, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.samplerParameteri(samp, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    alloc = allocator;
}

pub fn deinit() void {
    gl.deleteSamplers(1, &samp);
}

pub const TextureError = error{
    HandleCreationFailed,
};

pub const Texture = struct {
    id: gl.Uint,
    handle: gl.Uint64,
    width: u32,
    height: u32,

    pub fn fromData(data: []const u8) !Texture {
        var texture: Texture = undefined;
        texture.width = 0;
        texture.height = 0;

        const image = try zstbi.Image.loadFromMemory(data, 4);
        defer image.deinit();

        texture.width = image.width;
        texture.height = image.height;

        gl.genTextures(1, &texture.id);
        gl.bindTexture(gl.TEXTURE_2D, texture.id);

        const format = gl.RGBA;

        gl.texImage2D(gl.TEXTURE_2D, 0, format, image.width, image.height, 0, format, gl.UNSIGNED_BYTE, image.data);

        texture.handle = gl.getTextureHandleARB(texture.id);
        if (texture.handle == 0) {
            return TextureError.HandleCreationFailed;
        }

        return texture;
    }

    pub fn fromRaw(width: u32, height: u32, data: []const u8) !Texture {
        var texture: Texture = undefined;
        texture.width = width;
        texture.height = height;

        gl.genTextures(1, &texture.id);
        gl.bindTexture(gl.TEXTURE_2D, texture.id);

        const format = gl.RGBA;

        gl.texImage2D(gl.TEXTURE_2D, 0, format, @intCast(width), @intCast(height), 0, format, gl.UNSIGNED_BYTE, @ptrCast(data));

        texture.handle = gl.getTextureSamplerHandleARB(texture.id, samp);
        if (texture.handle == 0) {
            return TextureError.HandleCreationFailed;
        }

        return texture;
    }

    pub fn destroy(texture: *Texture) void {
        gl.deleteTextures(1, &texture.id);
    }

    pub fn makeResident(texture: *Texture) void {
        gl.makeTextureHandleResidentARB(texture.handle);
    }

    pub fn makeNonResident(texture: *Texture) void {
        gl.makeTextureHandleNonResidentARB(texture.handle);
    }
};
