#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
    float2 pos[4] = { {-1,1}, {1,1}, {-1,-1}, {1,-1} };
    float2 uv[4]  = { {0,0}, {1,0}, {0,1}, {1,1} };
    return VertexOut { float4(pos[vertexID], 0, 1), uv[vertexID] };
}

fragment float4 fragment_main(VertexOut in [[stage_in]], texture2d<float> tex [[texture(0)]]) {
    constexpr sampler s(filter::linear);
    return tex.sample(s, in.texCoord);
}
