#version 430 core

#extension GL_ARB_bindless_texture : require

struct SpriteVertexData {
    vec4 rect;
    vec2 origin;
    float rot;
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

    float rot = data[gl_InstanceID].rot;
    mat2 rotMat = mat2(cos(rot), -sin(rot), sin(rot), cos(rot));

    vec2 rotatedPos = rotMat * (i_pos - data[gl_InstanceID].origin);
    vec2 pos = rotatedPos * rect.zw + rect.xy;

    gl_Position = u_projection * vec4(pos, 0.0, 1.0);
}
