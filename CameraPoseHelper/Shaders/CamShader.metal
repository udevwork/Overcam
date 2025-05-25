#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

struct VertexOut {
    float4 position [[ position ]]; // Clip-space
    float2 texCoord;
};

// Универсальный vertex для камеры и reference
vertex VertexOut vertex_passthrough(uint vertexId [[ vertex_id ]],
                                    constant float2 *scaleFactors [[ buffer(0) ]]) {
    float2 scale = scaleFactors[0];

    float4 positions[4] = {
        float4(-scale.x, -scale.y, 0.0, 1.0),
        float4( scale.x, -scale.y, 0.0, 1.0),
        float4(-scale.x,  scale.y, 0.0, 1.0),
        float4( scale.x,  scale.y, 0.0, 1.0)
    };

    float2 texCoords[4] = {
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0)
    };

    VertexOut out;
    out.position = positions[vertexId];
    out.texCoord = texCoords[vertexId];
    return out;
}

// Камера — просто отрисовка
fragment float4 fragment_camera(VertexOut in [[ stage_in ]],
                                texture2d<float> tex [[ texture(0) ]],
                                sampler s [[ sampler(0) ]]) {
    return tex.sample(s, in.texCoord);
}

// Reference — микс поверх
fragment float4 fragment_overlay(VertexOut in [[ stage_in ]],
                                 texture2d<float> base [[ texture(0) ]],
                                 sampler s0 [[ sampler(0) ]],
                                 texture2d<float> overlay [[ texture(1) ]],
                                 sampler s1 [[ sampler(1) ]],
                                 constant float &alpha [[ buffer(0) ]]) {
    float4 baseColor = base.sample(s0, in.texCoord);
    float4 refColor  = overlay.sample(s1, in.texCoord);

    // Плавный градиент по краям
    float edge = 0.05; // 5% от ширины/высоты текстуры (можно подогнать)
    
    float fadeX = smoothstep(0.0, edge, in.texCoord.x) *
                  smoothstep(0.0, edge, 1.0 - in.texCoord.x);
    
    float fadeY = smoothstep(0.0, edge, in.texCoord.y) *
                  smoothstep(0.0, edge, 1.0 - in.texCoord.y);

    float fade = fadeX * fadeY;

    return mix(baseColor, refColor, alpha * fade);
}



// Бензин
[[ stitchable ]] float2 wave(float2 pos, float x, float y) {
    pos.y += sin(y + pos.y * 0.05) * 30;
    pos.x += cos(x + pos.x  * 0.05) * 10;
    return pos;
}
// Рандомный вектор градиента на клетке
float2 randomGradient(float2 cell) {
    float angle = fract(sin(dot(cell, float2(12.9898,78.233))) * 43758.5453) * 6.28318; // 2π
    return float2(cos(angle), sin(angle));
}

// Функция классического перлин нойза
float perlinNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);

    float2 g00 = randomGradient(i);
    float2 g10 = randomGradient(i + float2(1.0, 0.0));
    float2 g01 = randomGradient(i + float2(0.0, 1.0));
    float2 g11 = randomGradient(i + float2(1.0, 1.0));

    float d00 = dot(g00, f - float2(0.0, 0.0));
    float d10 = dot(g10, f - float2(1.0, 0.0));
    float d01 = dot(g01, f - float2(0.0, 1.0));
    float d11 = dot(g11, f - float2(1.0, 1.0));

    // Smootherstep интерполяция
    float2 u = f * f * (3.0 - 2.0 * f);

    float mixX0 = mix(d00, d10, u.x);
    float mixX1 = mix(d01, d11, u.x);
    float mixY = mix(mixX0, mixX1, u.y);

    return mixY;
}

[[ stitchable ]]
half4 oilSlick(float2 position, half4 color, float time, float counter) {
    float2 uv = position * 0.008;
    uv.x -= time * 0.05;
    uv.y += time * 0.03;
    float n = perlinNoise(uv * 2.0);
    n = (n + 1.0) * 1.3; // Приводим к диапазону 0..1
    // Используем высоту для цвета
    half4 lowColor = half4(0, 0.0, 0, 1.0);
    return mix(color, lowColor, 0.7 * n);
}
