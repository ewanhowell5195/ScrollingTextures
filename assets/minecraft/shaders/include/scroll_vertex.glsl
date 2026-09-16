#ifndef SCROLL_VERTEX_GLSL
#define SCROLL_VERTEX_GLSL

void scroll_vertex(vec2 uv, out vec4 bary, out vec3 corner) {
    int index = gl_VertexIndex & 3;
    bary = vec4(equal(ivec4(index), ivec4(0, 1, 2, 3)));
    corner = vec3(uv, index);
}

#endif
