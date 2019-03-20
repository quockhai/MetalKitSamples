import Foundation
import Metal
import simd

struct MBEVertex
{
    var position: packed_float4
    var texCoords: packed_float2
}

struct MBEUniforms
{
    var modelViewProjectionMatrix: float4x4
}

func MBECreateVertexDescriptor() -> MTLVertexDescriptor {
    let vertexDescriptor = MTLVertexDescriptor()
    vertexDescriptor.attributes[0].bufferIndex = 0
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[0].format = .float4
    vertexDescriptor.attributes[1].bufferIndex = 0
    vertexDescriptor.attributes[1].offset = MemoryLayout<float4>.stride
    vertexDescriptor.attributes[1].format = .float2
    vertexDescriptor.layouts[0].stepFunction = .perVertex
    vertexDescriptor.layouts[0].stepRate = 1
    vertexDescriptor.layouts[0].stride = MemoryLayout<MBEVertex>.stride
    return vertexDescriptor
}

func matrix_translation(_ translation: float3) -> float4x4
{
    var mat = float4x4()

    mat[0][0] = 1.0
    mat[1][1] = 1.0
    mat[2][2] = 1.0
    mat[3][0] = translation.x
    mat[3][1] = translation.y
    mat[3][2] = translation.z
    mat[3][3] = 1.0

    return mat
}

func matrix_rotation_about_axis(_ axis: float4, byAngleRadians angle: Float) -> float4x4
{
    var mat = float4x4()
    
    let c = cos(angle)
    let s = sin(angle)

    mat[0].x = c + axis.x * axis.x * (1 - c)
    mat[0].y = (axis.y * axis.x) * (1 - c) + axis.z * s
    mat[0].z = (axis.z * axis.x) - axis.y * s

    mat[1].x = (axis.x * axis.y) * (1 - c) - axis.z * s
    mat[1].y = c + axis.y * axis.y * (1 - c)
    mat[1].z = (axis.z * axis.y) + axis.x * s

    mat[2].x = (axis.x * axis.z) * (1 - c) + axis.y * s
    mat[2].y = (axis.y * axis.z) * (1 - c) - axis.x * s
    mat[2].z = c + axis.z * axis.z * (1 - c)

    mat[3].w = 1

    return mat
}

func matrix_perspective_projection(_ aspect: Float, fieldOfViewYRadians fovy: Float, near: Float, far: Float) -> float4x4
{
    var mat = float4x4()
    
    let yScale = 1 / tan(fovy * 0.5)
    let xScale = yScale / aspect
    let zRange = far - near
    let zScale = -(far + near) / zRange
    let wzScale = -2 * far * near / zRange
    
    mat[0].x = xScale
    mat[1].y = yScale
    mat[2].z = zScale
    mat[2].w = -1
    mat[3].z = wzScale

    return mat;
}
