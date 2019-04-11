//
//  MetalView.swift
//  MetalViewAnimation
//
//  Created by quockhai on 2019/4/11.
//  Copyright © 2019 Polymath. All rights reserved.
//

import UIKit
import MetalKit

struct Constants {
    var animateBy: Float = 0.0
}

class MetalView: MTKView {

    var commandQueue: MTLCommandQueue?
    
    var vertices: [Vertext] = [
        Vertext(position: float3(-1, 1, 0), color: float4(1, 0, 0, 1), texture: float2(0, 1)),
        Vertext(position: float3(-1, -1, 0), color: float4(0, 1, 0, 1), texture: float2(0, 0)),
        Vertext(position: float3(1, -1, 0), color: float4(0, 0, 1, 1), texture: float2(1, 0)),
        Vertext(position: float3(1, 1, 0), color: float4(1, 0, 1, 1), texture: float2(1, 1))
    ]
    
    var indices: [UInt16] = [
        0, 1, 2,
        2, 3, 0
    ]
    
    var pipelineState: MTLRenderPipelineState?
    var vertexBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!
    
    var constants = Constants()
    var time: Float = 0.0
    
    
    var texture: MTLTexture?
    var fragmentFunctionName: String?
    var samplerState: MTLSamplerState?
    
    init(frame frameRect: CGRect, device: MTLDevice?, imageName: String) {
        super.init(frame: frameRect, device: device)
        
        
        if let texture = setTexture(device: device!, imageName: imageName) {
            self.texture = texture
            self.fragmentFunctionName = "textured_fragment"
        }
        
        self.buildModel()
        self.buildSamplerState()
        self.buildPipelineState()
    }
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        
        self.buildModel()
        self.buildSamplerState()
        self.buildPipelineState()
    }
    
    
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        self.sendToGPU()
    }
    
    func buildSamplerState() {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        self.samplerState = self.device?.makeSamplerState(descriptor: samplerDescriptor)
    }
    
    func buildModel() {
        if let defaultDevice = MTLCreateSystemDefaultDevice() {
            self.device = defaultDevice
            self.commandQueue = device!.makeCommandQueue()

            self.vertexBuffer = self.device?.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertext>.size, options: [])
            self.indexBuffer = self.device?.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.size, options: [])
           
        } else {
            print("[MetalKit]: Your device is not supported Metal 🤪")
        }
    }
    
    func buildPipelineState() {
        let library = self.device!.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "vertex_shader")
        var fragmentFunction = library.makeFunction(name: "fragment_shader")
        if let functionName = self.fragmentFunctionName {
            fragmentFunction = library.makeFunction(name: functionName)
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<float3>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].offset = MemoryLayout<float3>.stride + MemoryLayout<float4>.stride
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertext>.stride
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            try self.pipelineState = device!.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            print("[MetalKit]: \(error.localizedDescription)")
        }
    }
    
    func sendToGPU() {
        guard let drawable = currentDrawable,
            let pipelineState = self.pipelineState,
            let indexBuffer = indexBuffer,
            let rpd = currentRenderPassDescriptor  else {
            return
        }
        
        self.time += 1 / Float(preferredFramesPerSecond)
        
        let animateBy = abs(sin(time) / 2 + 0.5)
        self.constants.animateBy = animateBy
        
        let commandBuffer = self.commandQueue!.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: rpd)
        commandEncoder?.setRenderPipelineState(pipelineState)
    
        commandEncoder?.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        commandEncoder?.setVertexBytes(&self.constants, length: MemoryLayout<Constants>.stride, index: 1)
        
        commandEncoder?.setFragmentTexture(self.texture, index: 0)
        commandEncoder?.setFragmentSamplerState(self.samplerState, index: 0)
    
        commandEncoder?.drawIndexedPrimitives(type: .triangle, indexCount: self.indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        commandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }

}

extension MetalView: Texturable {
    
    
    
}
