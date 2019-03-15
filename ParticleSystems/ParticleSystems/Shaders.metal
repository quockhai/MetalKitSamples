//
//  Shaders.metal
//  MetalTriangle
//
//  Created by quockhai on 2019/3/5.
//  Copyright © 2019 Polymath. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

struct Particle {
    float4x4 initial_matrix;
    float4x4 matrix;
    float4 color;
};

vertex VertexOut vertex_main(const VertexIn vertex_in [[stage_in]],
                             constant Particle *particles [[buffer(1)]],
                             uint instanceid [[instance_id]]) {
    VertexOut vertex_out;
    Particle particle = particles[instanceid];
    vertex_out.position = particle.matrix * vertex_in.position ;
    vertex_out.color = particle.color;
    return vertex_out;
}

fragment float4 fragment_main(VertexOut vertex_in [[stage_in]]) {
    return vertex_in.color;
}


//struct Particle {
//    float2 center;
//    float radius;
//};
//
//float distanceToParticle(float2 point, Particle p) {
//    return length(point - p.center) - p.radius;
//}
//
//kernel void compute(texture2d<float, access::write> output [[texture(0)]],
//                    constant float &time [[buffer(0)]],
//                    uint2 gid [[thread_position_in_grid]]) {
//    float width = output.get_width();
//    float height = output.get_height();
//    float2 uv = float2(gid) / float2(width, height);
//    float aspect = width / height;
//    uv.x *= aspect;
//    float2 center = float2(aspect / 2, time);
//    float radius = 0.05;
//    float stop = 1 - radius;
//    if (time >= stop) { center.y = stop; }
//    else center.y = time;
//    Particle p = Particle{center, radius};
//    float distance = distanceToParticle(uv, p);
//    float4 color = float4(1, 0.7, 0, 1);
//    if (distance > 0) { color = float4(0.2, 0.5, 0.7, 1); }
//    output.write(float4(color), gid);
//}
