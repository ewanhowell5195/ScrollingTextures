#version 330
#extension GL_ARB_separate_shader_objects : require
#extension GL_ARB_texture_query_levels : enable

#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:oit.glsl>
#include <minecraft:projection.glsl>
#include <minecraft:scroll.glsl>

uniform sampler2D Sampler0;

#ifdef GLINT
uniform sampler2D GlintSampler;
#endif

#ifndef OIT_ALPHA_ONLY
layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
#endif
layout(location = 2) in vec4 vertexColor;
#ifndef OIT_ALPHA_ONLY
layout(location = 3) in vec4 lightMapColor;
layout(location = 4) in vec4 overlayColor;
#endif
layout(location = 5) in vec2 texCoord0;
#ifdef GLINT
layout(location = 6) in vec2 texCoordGlint;
#endif
layout(location = 7) in vec4 bary;
layout(location = 8) flat in vec3 corner;

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

bool scroll_mipmapped(sampler2D s, vec2 uv) {
#ifdef GL_ARB_texture_query_levels
    return textureQueryLevels(s) > 1;
#else
    ivec2 size = textureSize(s, 0);
    ivec2 p = clamp(ivec2(floor(uv * vec2(size))), ivec2(0), size - 4);
    for (int i = 0; i < 4; i++) {
        ivec2 q = p + ivec2(i, 0);
        vec4 c1 = texelFetch(s, q >> 1, 1);
        if (c1 != texelFetch(s, q, 0) && c1 != vec4(0.0)) return true;
    }
    return false;
#endif
}

bool scroll_opaque_corners(sampler2D s, ivec4 rect) {
    return texelFetch(s, rect.xy, 0).a > 0.0
        && texelFetch(s, rect.zy - ivec2(1, 0), 0).a > 0.0
        && texelFetch(s, rect.xw - ivec2(0, 1), 0).a > 0.0
        && texelFetch(s, rect.zw - 1, 0).a > 0.0;
}

#ifndef OIT_ALPHA_ONLY
vec4 calculateFinalColor(vec4 color) {
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
    color *= lightMapColor;

    #ifdef GLINT
    vec4 glintColor = GlintAlpha * texture(GlintSampler, texCoordGlint);
    color.rgb += glintColor.rgb * glintColor.rgb;
    #endif

    #ifdef OIT_ACCUMULATE
    color = sampleColorForAccumulation(color);
    vec4 fogColor = vec4(FogColor.rgb * color.a, FogColor.a);
    #else
    vec4 fogColor = FogColor;
    #endif

    return apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, fogColor);
}
#endif

void main() {
    vec2 du = dFdx(texCoord0);
    vec2 dv = dFdy(texCoord0);
    ivec4 rect;
    bool scroll = scroll_rect(Sampler0, texCoord0, bary, corner, rect);
    scroll = scroll && ProjMat[3][3] < 0.5 && scroll_mipmapped(Sampler0, texCoord0) && scroll_opaque_corners(Sampler0, rect);
    vec4 color = textureGrad(Sampler0, scroll ? scroll_apply(Sampler0, texCoord0, rect) : texCoord0, du, dv);
    #ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) {
        discard;
    }
    #endif

    color *= vertexColor * ColorModulator;

    #ifdef GLINT
    color.a = max(color.a, GlintAlpha);
    #endif

    #ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(gl_FragCoord.z, color.a);
    #else
    fragColor = calculateFinalColor(color);
    #endif
}
