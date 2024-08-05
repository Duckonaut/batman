const std = @import("std");

const zopengl = @import("zopengl");
const gl = zopengl.bindings;

const zstbi = @import("zstbi");

const util = @import("util.zig");

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
        var image = try zstbi.Image.loadFromMemory(data, 4);

        const t = internalInit(image.width, image.height, image.data, gl.RGBA);
        image.deinit();
        return t;
    }

    pub fn fromRaw(width: u32, height: u32, data: []const u8) !Texture {
        return internalInit(width, height, data, gl.RGBA);
    }

    pub fn fromFile(path: []const u8) !Texture {
        const data = try util.readFileToEnd(path);
        const t = Texture.fromData(data);
        util.freeFileData(data);
        return t;
    }

    fn internalInit(width: u32, height: u32, data: []const u8, format: gl.Enum) !Texture {
        var texture: Texture = undefined;
        texture.width = width;
        texture.height = height;

        gl.genTextures(1, &texture.id);
        gl.bindTexture(gl.TEXTURE_2D, texture.id);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

        gl.texImage2D(
            gl.TEXTURE_2D,
            0,
            format,
            @intCast(width),
            @intCast(height),
            0,
            format,
            gl.UNSIGNED_BYTE,
            @ptrCast(data),
        );

        texture.handle = gl.getTextureSamplerHandleARB(texture.id, samp);
        if (texture.handle == 0) {
            return TextureError.HandleCreationFailed;
        }
        gl.makeTextureHandleResidentARB(texture.handle);

        return texture;
    }

    pub fn destroy(texture: *Texture) void {
        gl.makeTextureHandleNonResidentARB(texture.handle);

        gl.deleteTextures(1, &texture.id);
    }
};

pub const RenderTargetError = error{
    HandleCreationFailed,
};

pub const RenderTarget = struct {
    id: gl.Uint,
    fbid: gl.Uint,
    handle: gl.Uint64,
    width: u32,
    height: u32,

    pub fn fromSize(width: u32, height: u32) !RenderTarget {
        var renderTarget: RenderTarget = undefined;
        renderTarget.width = width;
        renderTarget.height = height;

        gl.genTextures(1, &renderTarget.id);
        gl.bindTexture(gl.TEXTURE_2D, renderTarget.id);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, @intCast(width), @intCast(height), 0, gl.RGBA, gl.UNSIGNED_BYTE, null);

        gl.genFramebuffers(1, &renderTarget.fbid);
        gl.bindFramebuffer(gl.FRAMEBUFFER, renderTarget.fbid);
        gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, renderTarget.id, 0);

        renderTarget.handle = gl.getTextureSamplerHandleARB(renderTarget.id, samp);
        if (renderTarget.handle == 0) {
            return RenderTargetError.HandleCreationFailed;
        }
        gl.makeTextureHandleResidentARB(renderTarget.handle);

        return renderTarget;
    }

    pub fn destroy(renderTarget: *RenderTarget) void {
        gl.makeTextureHandleNonResidentARB(renderTarget.handle);

        gl.deleteFramebuffers(1, &renderTarget.fbid);
        gl.deleteTextures(1, &renderTarget.id);
    }

    pub fn set(rt: *RenderTarget) void {
        gl.bindFramebuffer(gl.FRAMEBUFFER, rt.fbid);
        gl.viewport(0, 0, @intCast(rt.width), @intCast(rt.height));
    }

    pub fn unset() void {
        gl.bindFramebuffer(gl.FRAMEBUFFER, 0);
    }
};
