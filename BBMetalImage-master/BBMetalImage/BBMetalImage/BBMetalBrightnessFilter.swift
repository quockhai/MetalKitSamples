//
//  BBMetalBrightnessFilter.swift
//  BBMetalImage
//
//  Created by Kaibo Lu on 4/2/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

/// Adjusts the brightness of the image
public class BBMetalBrightnessFilter: BBMetalBaseFilter {
    /// The adjusted brightness (-1.0 ~ 1.0, with 0.0 as the default)
    public var brightness: Float
    
    public init(brightness: Float = 0) {
        self.brightness = brightness
        super.init(kernelFunctionName: "brightnessKernel")
    }
    
    public override func updateParameters(forComputeCommandEncoder encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&brightness, length: MemoryLayout<Float>.size, index: 0)
    }
    
    /*
     /// The adjusted exposure (-10.0 ~ 10.0, with 0.0 as the default)
     public var exposure: Float
     
     public init(exposure: Float = 0) {
     self.exposure = exposure
     super.init(kernelFunctionName: "exposureKernel")
     }
     
     public override func updateParameters(forComputeCommandEncoder encoder: MTLComputeCommandEncoder) {
     encoder.setBytes(&exposure, length: MemoryLayout<Float>.size, index: 0)
     }
     */
}
