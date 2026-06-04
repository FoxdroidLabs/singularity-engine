#version 460

void main() {
    vec2 position[] = vec2[](
        vec2(0.0, -1.0),
        vec2(-1.0, 1.0),
        vec2(1.0, 1.0)
    );
    gl_Position = vec4(position[gl_VertexIndex], 0.0, 1.0);
}
