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
    
    var vertices: [Float] = [
        -1, 1, 0,
        -1, -1, 0,
        1, -1, 0,
        1, 1, 0
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
    
        
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        
        self.buildModel()
        self.buildPipelineState()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        self.sendToGPU()
    }
    
    func buildModel() {
        if let defaultDevice = MTLCreateSystemDefaultDevice() {
            self.device = defaultDevice
            self.commandQueue = device!.makeCommandQueue()

            self.vertexBuffer = self.device?.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])
            self.indexBuffer = self.device?.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.size, options: [])
           
        } else {
            print("[MetalKit]: Your device is not supported Metal 🤪")
        }
    }
    
    func buildPipelineState() {
        let library = self.device!.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "vertex_shader")
        let fragmentFunction = library.makeFunction(name: "fragment_shader")
        
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
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
    
        commandEncoder?.drawIndexedPrimitives(type: .triangle, indexCount: self.indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        commandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }

}
