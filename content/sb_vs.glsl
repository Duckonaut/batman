#version 430 core

#extension GL_ARB_bindless_texture : require

struct SpriteVertexData {
    vec4 rect;
};

layout(binding = 0, std430) readonly buffer vertexSSBO {
    SpriteVertexData data[];
};

layout(location = 0) in vec2 i_pos;

uniform mat4 u_projection;

layout(location = 0) out vec2 a_uv;
layout(location = 1) flat out int a_instance;

void main() {
    a_uv = i_pos;
    a_instance = gl_InstanceID;

    vec4 rect = data[gl_InstanceID].rect;

    vec2 pos = i_pos * rect.zw + rect.xy;
    gl_Position = u_projection * vec4(pos, 0.0, 1.0);
}
