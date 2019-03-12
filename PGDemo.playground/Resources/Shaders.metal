
//
//  Shaders.metal
//  MetalTriangle
//
//  Created by quockhai on 2019/3/5.
//  Copyright © 2019 Polymath. All rights reserved.
//

//#include <metal_stdlib>
//using namespace metal;
//
//struct Vertex {
//    float4 position [[position]];
//    float4 color;
//};
//
//struct Uniforms {
//    float4x4 modelMatrix;
//};
//
////vertex Vertex vertex_func(constant Vertex *vertices [[buffer(0)]], uint vid [[vertex_id]]) {
////    return vertices[vid];
////}
////
////fragment float4 fragment_func(Vertex vert [[stage_in]]) {
////    return float4(0.7, 1, 1, 1);
////}
//
//vertex Vertex vertex_func(constant Vertex *vertices [[buffer(0)]],
//                          constant Uniforms &uniforms [[buffer(1)]],
//                          uint vid [[vertex_id]])
//{
//    float4x4 matrix = uniforms.modelMatrix;
//    Vertex in = vertices[vid];
//    Vertex out;
//    out.position = matrix * float4(in.position);
//    out.color = in.color;
//    return out;
//}
//
//fragment float4 fragment_func(Vertex vert [[stage_in]]) {
//    return vert.color;
//}


#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[position]];
    float4 color;
};

struct Uniforms {
    float4x4 modelMatrix;
};

vertex Vertex vertex_func(constant Vertex *vertices [[buffer(0)]],
                          constant Uniforms &uniforms [[buffer(1)]],
                          uint vid [[vertex_id]]) {
    float4x4 matrix = uniforms.modelMatrix;
    Vertex in = vertices[vid];
    Vertex out;
    out.position = matrix * float4(in.position);
    out.color = in.color;
    return out;
}

fragment float4 fragment_func(Vertex vert [[stage_in]]) {
    return vert.color;
}
