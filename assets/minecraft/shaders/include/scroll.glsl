#ifndef SCROLL_GLSL
#define SCROLL_GLSL

#include <minecraft:globals.glsl>

bool scroll_rect(sampler2D s, vec2 uv, vec4 bary, vec3 corner, out ivec4 rect) {
    vec4 bx = dFdx(bary);
    vec4 by = dFdy(bary);
    vec2 ux = dFdx(uv);
    vec2 uy = dFdy(uv);
    int k = int(corner.z + 0.5);
    int n = (k + 1) & 3;
    int o = (k + 2) & 3;
    int p = (k + 3) & 3;
    vec2 gu = vec2(ux.x, uy.x);
    vec2 gv = vec2(ux.y, uy.y);
    vec2 gon = vec2(bx[o] + bx[n], by[o] + by[n]);
    vec2 gop = vec2(bx[o] + bx[p], by[o] + by[p]);
    float scoreP = abs(gu.x * gop.y - gu.y * gop.x) * length(gon) + abs(gv.x * gon.y - gv.y * gon.x) * length(gop);
    float scoreQ = abs(gu.x * gon.y - gu.y * gon.x) * length(gop) + abs(gv.x * gop.y - gv.y * gop.x) * length(gon);
    bool nextSharesU = scoreP <= scoreQ;
    float B = bary[o] + (nextSharesU ? bary[p] : bary[n]);
    float C = bary[o] + (nextSharesU ? bary[n] : bary[p]);
    vec2 gB = nextSharesU ? gop : gon;
    vec2 gC = nextSharesU ? gon : gop;
    vec2 size = vec2(textureSize(s, 0));
    vec2 kt = corner.xy * size;
    vec2 t = uv * size;
    vec2 span = vec2(
        abs(B) >= 0.01 ? (t.x - kt.x) / B : dot(gu, gB) / dot(gB, gB) * size.x,
        abs(C) >= 0.01 ? (t.y - kt.y) / C : dot(gv, gC) / dot(gC, gC) * size.y
    );
    vec4 range = vec4(min(kt, kt + span), max(kt, kt + span));
    rect = ivec4(round(range));
    return all(lessThan(abs(range - vec4(rect)), vec4(0.25))) && all(greaterThanEqual(t, vec2(rect.xy))) && all(lessThan(t, vec2(rect.zw)));
}

vec2 scroll_apply(sampler2D s, vec2 uv, ivec4 rect) {
    float width = float(textureSize(s, 0).x);
    int w = rect.z - rect.x;
    int localX = int(floor(uv.x * width)) - rect.x;
    int shift = int(floor(GameTime * 24000.0)) % w;
    int src = (localX + w - shift) % w;
    return vec2(uv.x + float(src - localX) / width, uv.y);
}

vec2 scroll_uv(sampler2D s, vec2 uv, vec4 bary, vec3 corner) {
    ivec4 rect;
    return scroll_rect(s, uv, bary, corner, rect) ? scroll_apply(s, uv, rect) : uv;
}

vec4 scroll_sample(sampler2D s, vec2 uv, vec4 bary, vec3 corner) {
    vec2 du = dFdx(uv);
    vec2 dv = dFdy(uv);
    return textureGrad(s, scroll_uv(s, uv, bary, corner), du, dv);
}

#endif
