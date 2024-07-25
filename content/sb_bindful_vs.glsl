#version 430 core


layout(location = 0) in vec2 i_pos;

uniform mat4 u_projection;
uniform vec4 u_rect;

layout(location = 0) out vec2 a_uv;

void main() {
    a_uv = i_pos;

    vec2 pos = i_pos * u_rect.zw + u_rect.xy;
    gl_Position = u_projection * vec4(pos, 0.0, 1.0);
}

