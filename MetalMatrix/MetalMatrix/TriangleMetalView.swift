//
//  TriangleMetalView.swift
//  MetalTriangle
//
//  Created by quockhai on 2019/3/5.
//  Copyright © 2019 Polymath. All rights reserved.
//

import UIKit
import MetalKit

class TriangleMetalView: MTKView {
    
    var commandQueue: MTLCommandQueue?
    var rps: MTLRenderPipelineState?
    var vertexBuffer: MTLBuffer!
    var uniformBuffer: MTLBuffer!
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        
        self.createBuffer()
        self.registerShaders()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        self.sendToGPU()
    }
    
    func createBuffer() {
        if let defaultDevice = MTLCreateSystemDefaultDevice() {
            self.device = defaultDevice
            self.commandQueue = device!.makeCommandQueue()
            
            
            let vertexData = [Vertex(position: [-1.0, -1.0, 0.0, 1.0], color: [1, 0, 0, 1]),
                               Vertex(position: [ 1.0, -1.0, 0.0, 1.0], color: [0, 1, 0, 1]),
                               Vertex(position: [ 0.0,  1.0, 0.0, 1.0], color: [0, 0, 1, 1])
            ]
            self.vertexBuffer = device!.makeBuffer(bytes: vertexData, length: MemoryLayout<Vertex>.size * 3, options:[])
            
            self.uniformBuffer = device!.makeBuffer(length: MemoryLayout<Float>.size * 16, options: [])
            let bufferPointer = self.uniformBuffer.contents()
            memcpy(bufferPointer, Matrix().modelMatrix(Matrix()).m, MemoryLayout<Float>.size * 16)
        } else {
            print("[MetalKit]: Your device is not supported Metal 🤪")
        }
    }
    
    
    func registerShaders() {
        let library = device!.makeDefaultLibrary()!
        let vertex_func = library.makeFunction(name: "vertex_func")
        let frag_func = library.makeFunction(name: "fragment_func")
        
        
        let rpld = MTLRenderPipelineDescriptor()
        rpld.vertexFunction = vertex_func
        rpld.fragmentFunction = frag_func
        rpld.colorAttachments[0].pixelFormat = .bgra8Unorm
        do {
            try self.rps = device!.makeRenderPipelineState(descriptor: rpld)
        } catch let error {
            print("[MetalKit]: \(error.localizedDescription)")
        }
    }
    
    func sendToGPU() {
        if let drawable = currentDrawable, let rpd = currentRenderPassDescriptor {
            rpd.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0)
            
            let commandBuffer = self.commandQueue!.makeCommandBuffer()
            let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: rpd)
            commandEncoder?.setRenderPipelineState(self.rps!)
            commandEncoder?.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
            commandEncoder?.setVertexBuffer(self.uniformBuffer, offset: 0, index: 1)
            commandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
            commandEncoder?.endEncoding()
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }
    }
}
