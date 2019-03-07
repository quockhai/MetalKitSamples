//
//  Shaders.metal
//  MetalTriangle
//
//  Created by quockhai on 2019/3/5.
//  Copyright © 2019 Polymath. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[position]];
    float4 color;
};

vertex Vertex vertex_func(constant Vertex *vertices [[buffer(0)]], uint vid [[vertex_id]]) {
    return vertices[vid];
}

//fragment float4 fragment_func(Vertex vert [[stage_in]]) {
//    return float4(0.7, 1, 1, 1);
//}

fragment float4 fragment_func(Vertex vert [[stage_in]]) {
    return vert.color;
}
