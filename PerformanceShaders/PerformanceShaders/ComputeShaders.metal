#include <metal_stdlib>

using namespace metal;

struct MBEImageSaturationParams
{
    int2 offset;
    uint2 clipOrigin;
    uint2 clipMax;
    float saturation;
};

kernel void image_saturation(constant MBEImageSaturationParams *params [[buffer(0)]],
                             texture2d<half, access::sample> sourceTexture [[texture(0)]],
                             texture2d<half, access::write> destTexture [[texture(1)]],
                             sampler samp [[sampler(0)]],
                             uint2 gridPosition [[thread_position_in_grid]])
{
    // Sample the source texture at the offset sample point
    float2 sourceCoords = float2(gridPosition) + float2(params->offset);
    half4 color = sourceTexture.sample(samp, sourceCoords);

    // Calculate the perceptual luminance value of the sampled color.
    // Values taken from Rec. ITU-R BT.601-7
    half4 luminanceWeights = half4(0.299, 0.587, 0.114, 0);
    half luminance = dot(color, luminanceWeights);

    // Build a grayscale color that matches the perceived luminance,
    // then blend between it and the source color to get the desaturated
    // color value.
    half4 gray = half4(luminance, luminance, luminance, 1.0);
    half4 desaturated = mix(gray, color, half(params->saturation));

    uint2 destCoords = gridPosition + params->clipOrigin;

    // Write the blended, desaturated color into the destination texture if
    // the grid position is inside the clip rect.
    if (destCoords.x < params->clipMax.x &&
        destCoords.y < params->clipMax.y)
    {
        destTexture.write(desaturated, destCoords);
    }
}