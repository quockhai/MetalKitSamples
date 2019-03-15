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
    
    var queue: MTLCommandQueue!
    var vertexBuffer: MTLBuffer!
    var uniformBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!
    var rps: MTLRenderPipelineState!
    var rotation: Float = 0
    
//    override public init() {
//        super.init()
//        device = MTLCreateSystemDefaultDevice()
//        queue = device.makeCommandQueue()
//        createBuffers()
//        createPipeline()
//    }
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        
        if let defaultDevice = MTLCreateSystemDefaultDevice() {
            self.device = defaultDevice
            self.queue = self.device!.makeCommandQueue()
            
            createBuffers()
            createPipeline()
        } else {
            print("[MetalKit]: Your device is not supported Metal 🤪")
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createBuffers() {
        let vertexData = [
            Vertex(pos: [-1.0, -1.0,  1.0, 1.0], col: [1, 1, 1, 1]),
            Vertex(pos: [ 1.0, -1.0,  1.0, 1.0], col: [1, 0, 0, 1]),
            Vertex(pos: [ 1.0,  1.0,  1.0, 1.0], col: [1, 1, 0, 1]),
            Vertex(pos: [-1.0,  1.0,  1.0, 1.0], col: [0, 1, 0, 1]),
            Vertex(pos: [-1.0, -1.0, -1.0, 1.0], col: [0, 0, 1, 1]),
            Vertex(pos: [ 1.0, -1.0, -1.0, 1.0], col: [1, 0, 1, 1]),
            Vertex(pos: [ 1.0,  1.0, -1.0, 1.0], col: [0, 0, 0, 1]),
            Vertex(pos: [-1.0,  1.0, -1.0, 1.0], col: [0, 1, 1, 1])]
        
        let indexData: [UInt16] = [0, 1, 2, 2, 3, 0,   // front
            1, 5, 6, 6, 2, 1,   // right
            3, 2, 6, 6, 7, 3,   // top
            4, 5, 1, 1, 0, 4,   // bottom
            4, 0, 3, 3, 7, 4,   // left
            7, 6, 5, 5, 4, 7]   // back
        
        vertexBuffer = device!.makeBuffer(bytes: vertexData, length: MemoryLayout<Vertex>.size * vertexData.count, options: [])
        indexBuffer = device!.makeBuffer(bytes: indexData, length: MemoryLayout<UInt16>.size * indexData.count , options: [])
        uniformBuffer = device!.makeBuffer(length: MemoryLayout<matrix_float4x4>.size, options: [])
    }
    
    func createPipeline() {
//        let input: String?
        let library: MTLLibrary
        let vert_func: MTLFunction
        let frag_func: MTLFunction
        do {
            library = device!.makeDefaultLibrary()!
            vert_func = library.makeFunction(name: "vertex_func")!
            frag_func = library.makeFunction(name: "fragment_func")!
            let rpld = MTLRenderPipelineDescriptor()
            rpld.vertexFunction = vert_func
            rpld.fragmentFunction = frag_func
            rpld.colorAttachments[0].pixelFormat = .bgra8Unorm
            rps = try device!.makeRenderPipelineState(descriptor: rpld)
        } catch let e {
            Swift.print("\(e)")
        }
    }
    
    func update() {
        let scaled = scalingMatrix(scale: 0.5)
        rotation += 1 / 100 * Float.pi / 4
        let rotatedY = rotationMatrix(angle: rotation, axis: float3(0, 1, 0))
        let rotatedX = rotationMatrix(angle: Float.pi / 4, axis: float3(1, 0, 0))
        let modelMatrix = matrix_multiply(matrix_multiply(rotatedX, rotatedY), scaled)
        let cameraPosition = vector_float3(0, 0, -3)
        let viewMatrix = translationMatrix(position: cameraPosition)
        let projMatrix = projectionMatrix(near: 0, far: 10, aspect: 1, fovy: 1)
        let modelViewProjectionMatrix = matrix_multiply(projMatrix, matrix_multiply(viewMatrix, modelMatrix))
        let bufferPointer = uniformBuffer.contents()
        var uniforms = Uniforms(modelViewProjectionMatrix: modelViewProjectionMatrix)
        memcpy(bufferPointer, &uniforms, MemoryLayout<Uniforms>.size)
    }
    
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        update()
        if let rpd = currentRenderPassDescriptor,
            let drawable = currentDrawable,
            let commandBuffer = queue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) {
            rpd.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0)
            commandEncoder.setRenderPipelineState(rps)
            commandEncoder.setFrontFacing(.counterClockwise)
            commandEncoder.setCullMode(.back)
            commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
            commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBuffer.length / MemoryLayout<UInt16>.size, indexType: MTLIndexType.uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
            commandEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
    
//    var queue: MTLCommandQueue!
//    var firstState: MTLComputePipelineState!
//    var secondState: MTLComputePipelineState!
//    var particleBuffer: MTLBuffer!
//    let particleCount = 10000
//    var particles = [Particle]()
//    let side = 1200
//
//
//    override init(frame frameRect: CGRect, device: MTLDevice?) {
//        super.init(frame: frameRect, device: device)
//
//        self.framebufferOnly = false
//
//
//        if let defaultDevice = MTLCreateSystemDefaultDevice() {
//            self.device = defaultDevice
//            self.queue = self.device!.makeCommandQueue()
//
//            initializeMetal()
//            initializeBuffers()
//        } else {
//            print("[MetalKit]: Your device is not supported Metal 🤪")
//        }
//    }
//
//    required init(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func initializeMetal() {
//        do {
//            let library = device!.makeDefaultLibrary()
//            guard let firstPass = library!.makeFunction(name: "firstPass") else { return }
//            firstState = try device!.makeComputePipelineState(function: firstPass)
//            guard let secondPass = library!.makeFunction(name: "secondPass") else { return }
//            secondState = try device!.makeComputePipelineState(function: secondPass)
//        } catch let e { print(e) }
//    }
//
//    func initializeBuffers() {
//        for _ in 0 ..< particleCount {
//            let particle = Particle(position: float2(Float(arc4random() %  UInt32(side)), Float(arc4random() % UInt32(side))), velocity: float2((Float(arc4random() %  10) - 5) / 10, (Float(arc4random() %  10) - 5) / 10))
//            particles.append(particle)
//        }
//        let size = particles.count * MemoryLayout<Particle>.size
//        particleBuffer = device!.makeBuffer(bytes: &particles, length: size, options: [])
//    }
//
//
//    override func draw(_ rect: CGRect) {
//        super.draw(rect)
//
//        if let drawable = currentDrawable,
//            let commandBuffer = queue.makeCommandBuffer(),
//            let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
//
//
//            // first pass
//            commandEncoder.setComputePipelineState(firstState)
//            commandEncoder.setTexture(drawable.texture, index: 0)
////            let w = firstState.threadExecutionWidth
////            let h = firstState.maxTotalThreadsPerThreadgroup / w
//            let threadsPerGroup = MTLSizeMake(1, 1, 1)//MTLSizeMake(w, h, 1)
//            var threadsPerGrid = MTLSizeMake(side, side, 1)
//            commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
//
//
//            // second pass
//            commandEncoder.setComputePipelineState(secondState)
//            commandEncoder.setTexture(drawable.texture, index: 0)
//            commandEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
//            threadsPerGrid = MTLSizeMake(particleCount, 1, 1)
//            commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
//            commandEncoder.endEncoding()
//            commandBuffer.present(drawable)
//            commandBuffer.commit()
//        }
//    }

}
