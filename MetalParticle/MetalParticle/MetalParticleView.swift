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
    var commandQueue: MTLCommandQueue! = nil
    var computePipelineState: MTLComputePipelineState! = nil
    var timerBuffer: MTLBuffer! = nil
    var timer: Float = 0
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        
        self.framebufferOnly = false
        
        
        if let defaultDevice = MTLCreateSystemDefaultDevice() {
            self.device = defaultDevice
            self.commandQueue = self.device!.makeCommandQueue()
            self.registerShaders()
        } else {
            print("[MetalKit]: Your device is not supported Metal 🤪")
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func registerShaders() {
        do {
            let library = device!.makeDefaultLibrary()
            guard let kernel = library!.makeFunction(name: "compute") else { return }
            self.computePipelineState = try device!.makeComputePipelineState(function: kernel)
        } catch let error {
            print("\(error.localizedDescription)")
        }
        self.timerBuffer = device!.makeBuffer(length: MemoryLayout<Float>.size, options: [])
    }
    
    func update() {
        self.timer += 0.01
        let bufferPointer = self.timerBuffer.contents()
        memcpy(bufferPointer, &self.timer, MemoryLayout<Float>.size)
    }
    
    
    override func draw(_ rect: CGRect) {
        if let drawable = currentDrawable, let commandBuffer = self.commandQueue.makeCommandBuffer(), let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
            commandEncoder.setComputePipelineState(self.computePipelineState)
            commandEncoder.setTexture(drawable.texture, index: 0)
            commandEncoder.setBuffer(self.timerBuffer, offset: 0, index: 0)
            
            update()
            
            let threadGroupCount = MTLSizeMake(8, 8, 1)
            let threadGroups = MTLSizeMake(drawable.texture.width / threadGroupCount.width, drawable.texture.height / threadGroupCount.height, 1)
            commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
            commandEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
