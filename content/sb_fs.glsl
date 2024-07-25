#version 430 core

#extension GL_ARB_bindless_texture : require

struct SpriteDrawData {
    sampler2D texture;
    vec4 uvRect;
    vec4 color;
};

layout(binding = 1, std430) readonly buffer drawSSBO {
    SpriteDrawData data[];
};

layout(location = 0) in vec2 a_uv;
layout(location = 1) flat in int a_instance;

layout(location = 0) out vec4 o_color;

void main() {
    vec4 color = data[a_instance].color;
    vec4 uvRect = data[a_instance].uvRect;

    vec2 uv = uvRect.xy + a_uv * uvRect.zw;
    vec4 texColor = texture(data[a_instance].texture, uv);

    o_color = vec4((texColor * color).rgb, 1.0);
}

