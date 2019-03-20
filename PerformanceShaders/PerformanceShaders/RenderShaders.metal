#include <metal_stdlib>

using namespace metal;

struct Uniforms
{
    float4x4 modelViewProjectionMatrix;
};

struct ColoredVertexIn
{
    packed_float4 position;
    packed_float2 texCoords;
};

struct ColoredVertex
{
    float4 position [[position]];
    float2 texCoords;
};

vertex ColoredVertex project_vertex(constant ColoredVertexIn *vertices [[buffer(0)]],
                                    constant Uniforms *uniforms      [[buffer(1)]],
                                    uint vid [[vertex_id]])
{
    ColoredVertexIn inVertex = vertices[vid];
    ColoredVertex outVertex;
    
    outVertex.position = uniforms->modelViewProjectionMatrix * float4(inVertex.position);
    outVertex.texCoords = inVertex.texCoords;
    
    return outVertex;
};

fragment half4 texture_fragment(ColoredVertex vert [[stage_in]],
                                texture2d<float> diffuseTexture [[texture(0)]],
                                sampler samplr [[sampler(0)]])
{
    float4 diffuse = diffuseTexture.sample(samplr, vert.texCoords);
    return half4(diffuse);
};
