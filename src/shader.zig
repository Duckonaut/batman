const std = @import("std");

const zopengl = @import("zopengl");
const gl = zopengl.bindings;

const m = @import("math.zig");

var alloc: std.mem.Allocator = undefined;

pub fn init(allocator: std.mem.Allocator) void {
    alloc = allocator;
}

pub fn deinit() void {}

pub const ShaderError = error{
    CompilationFailed,
    LinkingFailed,
};

pub const Shader = struct {
    id: gl.Uint,

    pub fn fromSource(vert_source: []const u8, frag_source: []const u8) !Shader {
        var shader: Shader = undefined;

        const vert = gl.createShader(gl.VERTEX_SHADER);
        defer gl.deleteShader(vert);
        gl.shaderSource(vert, 1, @ptrCast(&vert_source), &@intCast(vert_source.len));
        gl.compileShader(vert);

        var success: gl.Int = undefined;
        gl.getShaderiv(vert, gl.COMPILE_STATUS, &success);

        if (success != gl.TRUE) {
            var log_len: gl.Int = 0;
            gl.getShaderiv(vert, gl.INFO_LOG_LENGTH, &log_len);
            const log = try alloc.alloc(u8, @intCast(log_len));
            defer alloc.free(log);

            gl.getShaderInfoLog(vert, log_len, null, @ptrCast(log));
            std.debug.print("Vertex shader compilation failed: {s}\n", .{log});
            return ShaderError.CompilationFailed;
        }

        const frag = gl.createShader(gl.FRAGMENT_SHADER);
        defer gl.deleteShader(frag);
        gl.shaderSource(frag, 1, @ptrCast(&frag_source), &@intCast(frag_source.len));
        gl.compileShader(frag);

        gl.getShaderiv(frag, gl.COMPILE_STATUS, &success);
        if (success != gl.TRUE) {
            var log_len: gl.Int = 0;
            gl.getShaderiv(frag, gl.INFO_LOG_LENGTH, &log_len);
            const log = try alloc.alloc(u8, @intCast(log_len));
            defer alloc.free(log);

            gl.getShaderInfoLog(frag, log_len, null, @ptrCast(log));
            std.debug.print("Fragment shader compilation failed: {s}\n", .{log});

            return ShaderError.CompilationFailed;
        }

        shader.id = gl.createProgram();
        gl.attachShader(shader.id, vert);
        gl.attachShader(shader.id, frag);
        gl.linkProgram(shader.id);

        gl.getProgramiv(shader.id, gl.LINK_STATUS, &success);
        if (success != gl.TRUE) {
            var log_len: gl.Int = 0;
            gl.getProgramiv(shader.id, gl.INFO_LOG_LENGTH, &log_len);
            const log = try alloc.alloc(u8, @intCast(log_len));
            defer alloc.free(log);

            gl.getProgramInfoLog(shader.id, log_len, null, @ptrCast(log));
            std.debug.print("Shader linking failed: {s}\n", .{log});

            return ShaderError.LinkingFailed;
        }

        return shader;
    }

    pub fn use(self: *Shader) void {
        gl.useProgram(self.id);
    }

    pub fn setUniformMat4(self: *Shader, name: [:0]const u8, mat: m.Mat4) void {
        const loc = gl.getUniformLocation(self.id, @ptrCast(name));
        gl.uniformMatrix4fv(loc, 1, gl.FALSE, @ptrCast(&mat.fields[0][0]));
    }

    pub fn setUniformVec4(self: *Shader, name: [:0]const u8, vec: m.Vec4) void {
        const loc = gl.getUniformLocation(self.id, @ptrCast(name));
        gl.uniform4f(loc, vec.x, vec.y, vec.z, vec.w);
    }
};
