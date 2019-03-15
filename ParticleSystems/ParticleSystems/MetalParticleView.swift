//
//  TriangleMetalView.swift
//  MetalTriangle
//
//  Created by quockhai on 2019/3/5.
//  Copyright © 2019 Polymath. All rights reserved.
//

import UIKit
import MetalKit

struct Particle {
    var position: float2
    var velocity: float2
}

class MetalParticleView: MTKView {
    
    
    var queue: MTLCommandQueue!
    var firstState: MTLComputePipelineState!
    var secondState: MTLComputePipelineState!
    var particleBuffer: MTLBuffer!
    let particleCount = 10000
    var particles = [Particle]()
    let side = 1200
    
//    override public init() {
//        super.init()
//        initializeMetal()
//        initializeBuffers()
//    }
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        
        self.framebufferOnly = false
        
        
        if let defaultDevice = MTLCreateSystemDefaultDevice() {
            self.device = defaultDevice
            self.queue = self.device!.makeCommandQueue()
            
            initializeMetal()
            initializeBuffers()
        } else {
            print("[MetalKit]: Your device is not supported Metal 🤪")
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initializeBuffers() {
        for _ in 0 ..< particleCount {
            let particle = Particle(position: float2(Float(arc4random() %  UInt32(side)), Float(arc4random() % UInt32(side))), velocity: float2((Float(arc4random() %  10) - 5) / 10, (Float(arc4random() %  10) - 5) / 10))
            particles.append(particle)
        }
        let size = particles.count * MemoryLayout<Particle>.size
        particleBuffer = device!.makeBuffer(bytes: &particles, length: size, options: [])
    }
    
    func initializeMetal() {
        do {
            let library = device!.makeDefaultLibrary()
            guard let firstPass = library!.makeFunction(name: "firstPass") else { return }
            firstState = try device!.makeComputePipelineState(function: firstPass)
            guard let secondPass = library!.makeFunction(name: "secondPass") else { return }
            secondState = try device!.makeComputePipelineState(function: secondPass)
        } catch let e { print(e) }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if let drawable = currentDrawable,
            let commandBuffer = queue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
            
            
            // first pass
            commandEncoder.setComputePipelineState(firstState)
            commandEncoder.setTexture(drawable.texture, index: 0)
            let w = firstState.threadExecutionWidth
            let h = firstState.maxTotalThreadsPerThreadgroup / w
            let threadsPerGroup = MTLSizeMake(w, h, 1)
            var threadsPerGrid = MTLSizeMake(side, side, 1)
            commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
            
            
            // second pass
            commandEncoder.setComputePipelineState(secondState)
            commandEncoder.setTexture(drawable.texture, index: 0)
            commandEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
            threadsPerGrid = MTLSizeMake(particleCount, 1, 1)
            commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
            commandEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }

}
