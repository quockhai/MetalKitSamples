//
//  TriangleMetalView.swift
//  MetalTriangle
//
//  Created by quockhai on 2019/3/5.
//  Copyright © 2019 Polymath. All rights reserved.
//

import UIKit
import MetalKit

class MetalParticleView: MTKView {
    
    
    
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var model: MTKMesh!
    var particles: [Particle]!
    var particlesBuffer: MTLBuffer!
    var timer: Float = 0
    
    struct Particle {
        var initialMatrix = matrix_identity_float4x4
        var matrix = matrix_identity_float4x4
        var color = float4()
    }
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)

        self.framebufferOnly = false


        if let defaultDevice = MTLCreateSystemDefaultDevice() {
            self.device = defaultDevice
            self.commandQueue = self.device!.makeCommandQueue()
            
            self.initializeMetal()
        } else {
            print("[MetalKit]: Your device is not supported Metal 🤪")
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func initializeBuffers() {
        self.particles = [Particle](repeatElement(Particle(), count: 1000))
        self.particlesBuffer = device!.makeBuffer(length: particles.count * MemoryLayout<Particle>.stride, options: [])!
        var pointer = particlesBuffer.contents().bindMemory(to: Particle.self, capacity: particles.count)
        for _ in self.particles {
            pointer.pointee.initialMatrix = self.translate(by: [Float(drand48()) / 10, Float(drand48()) * 10, 0])
            pointer.pointee.color = float4(0.2, 0.6, 0.9, 1)
            pointer = pointer.advanced(by: 1)
        }
        let allocator = MTKMeshBufferAllocator(device: device!)
        let sphere = MDLMesh(sphereWithExtent: [0.01, 0.01, 0.01], segments: [8, 8], inwardNormals: false, geometryType: .triangles, allocator: allocator)
        
        do {
            self.model = try MTKMesh(mesh: sphere, device: device!)
            
        }   catch let error {
            print("[MetalKit] error: \(error.localizedDescription)")
        }
    }
    
    func initializeMetal() {
        self.initializeBuffers()
        let library: MTLLibrary
        do {
            library = device!.makeDefaultLibrary()!
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            descriptor.vertexFunction = library.makeFunction(name: "vertex_main")
            descriptor.fragmentFunction = library.makeFunction(name: "fragment_main")
            descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(model.vertexDescriptor)
            self.pipelineState = try device!.makeRenderPipelineState(descriptor: descriptor)
        } catch let error as NSError {
            print("[MetalKit] error: \(error.localizedDescription)")
        }
    }
    
    func translate(by: float3) -> float4x4 {
        return float4x4(columns: (
            float4( 1,  0,  0,  0),
            float4( 0,  1,  0,  0),
            float4( 0,  0,  1,  0),
            float4( by.x,  by.y,  by.z,  1)
        ))
    }
    
    func update() {
        self.timer += 0.01
        var pointer = self.particlesBuffer.contents().bindMemory(to: Particle.self, capacity: self.particles.count)
        for _ in self.particles {
            pointer.pointee.matrix = self.translate(by: [0, -3 * self.timer, 0]) * pointer.pointee.initialMatrix
            pointer = pointer.advanced(by: 1)
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.update()
        guard let commandBuffer = self.commandQueue.makeCommandBuffer(),
            let descriptor = currentRenderPassDescriptor,
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
            let drawable = currentDrawable else { fatalError() }
        let submesh = self.model.submeshes[0]
        commandEncoder.setRenderPipelineState(self.pipelineState)
        commandEncoder.setVertexBuffer(self.model.vertexBuffers[0].buffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(self.particlesBuffer, offset: 0, index: 1)
        commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: 0, instanceCount: self.particles.count)
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
