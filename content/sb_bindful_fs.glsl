#version 430 core

uniform sampler2D u_texture;
uniform vec4 u_uvRect;
uniform vec4 u_color;

layout(location = 0) in vec2 a_uv;

layout(location = 0) out vec4 o_color;

void main() {
    vec2 uv = u_uvRect.xy + a_uv * u_uvRect.zw;
    vec4 texColor = texture(u_texture, uv);

    o_color = vec4((texColor * u_color).rgb, 1.0);
}
