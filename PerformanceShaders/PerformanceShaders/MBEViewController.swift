import UIKit
import Metal
import MetalKit
import MetalPerformanceShaders

// Size of buffers that hold vertex and uniform data.
// These bounds are pretty tight, so if you modify this
// code to draw more geometry, you'll want to make them larger.
let MBEVertexDataSize = 128
let MBEUniformDataSize = 64
let MBEMaxInflightBuffers = 3

// Vertex data for drawing a textured square
// The texture coordinates (s, t) below simply select an
// interesting square region of the included texture.
var vertexData:[Float] =
[
//    x     y    z    w    s    t
    -1.0,  1.0, 0.0, 1.0, 0.0, 0.0,
    -1.0, -1.0, 0.0, 1.0, 0.0, 1.0,
     1.0,  1.0, 0.0, 1.0, 1.0, 0.0,
     1.0, -1.0, 0.0, 1.0, 1.0, 1.0,
]

// This copying allocator can be used by certain Metal Performance Shader kernels
// to allocate a target texture when the are unable to operate in-place
let MBEFallbackAllocator =
{ (kernel: MPSKernel, commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture) -> MTLTexture in
    let descriptor = sourceTexture.matchingDescriptor()
    descriptor.usage.formUnion(.shaderWrite)
    return sourceTexture.device.makeTexture(descriptor: descriptor)!
}

class MBEViewController:UIViewController, MTKViewDelegate {
    
    let device: MTLDevice = MTLCreateSystemDefaultDevice()!
    
    var commandQueue: MTLCommandQueue! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var vertexBuffer: MTLBuffer! = nil
    var uniformBuffer: MTLBuffer! = nil
    var sampler: MTLSamplerState! = nil

    var kernelSourceTexture: MTLTexture? = nil
    var kernelDestTexture: MTLTexture? = nil

    let inflightSemaphore = DispatchSemaphore(value: MBEMaxInflightBuffers)
    var bufferIndex = 0

    var gaussianBlurKernel: MPSUnaryImageKernel!
    var thresholdKernel: MPSUnaryImageKernel!
    var edgeKernel: MPSUnaryImageKernel!
    var saturationKernel: MBEImageSaturation!

    var selectedKernel: MPSUnaryImageKernel!

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(MPSSupportsMTLDevice(device), "This device does not support Metal Performance Shaders")

        let view = self.view as! MTKView
        view.device = device
        view.delegate = self

        buildKernels()
        loadAssets()
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }

    func buildKernels() {
        gaussianBlurKernel = MPSImageGaussianBlur(device: device, sigma: 3.0)
        thresholdKernel = MPSImageThresholdToZero(device: device, thresholdValue: 0.5, linearGrayColorTransform: nil)
        edgeKernel = MPSImageSobel(device: device)
        saturationKernel = MBEImageSaturation(device: device, saturationFactor: 0)

        selectedKernel = saturationKernel
    }

    func loadAssets() {
        let view = self.view as! MTKView
        commandQueue = device.makeCommandQueue()
        commandQueue.label = "Command queue"
        
        let defaultLibrary = device.makeDefaultLibrary()!
        let vertexProgram = defaultLibrary.makeFunction(name: "project_vertex")!
        let fragmentProgram = defaultLibrary.makeFunction(name: "texture_fragment")!

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexDescriptor = MBECreateVertexDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineStateDescriptor.sampleCount = view.sampleCount

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .linear
        sampler = device.makeSamplerState(descriptor: samplerDescriptor)

        let textureLoader = MTKTextureLoader(device: device)

        do {
            if let image = UIImage(named: "mandrill") {
                let options = [ MTKTextureLoader.Option.SRGB : NSNumber(value: false) ]
                try kernelSourceTexture = textureLoader.newTexture(cgImage: image.cgImage!, options: options)
                let descriptor = kernelSourceTexture!.matchingDescriptor()
                descriptor.usage.formUnion(.shaderWrite)
                kernelDestTexture = device.makeTexture(descriptor: descriptor)
            } else {
                print("Failed to load texture image from main bundle")
            }
        }
        catch let error {
            print("Failed to create texture from image, error \(error)")
        }

        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
        
        vertexBuffer = device.makeBuffer(length: MBEVertexDataSize * MBEMaxInflightBuffers, options: [])
        vertexBuffer.label = "vertices"
        
        uniformBuffer = device.makeBuffer(length: MBEUniformDataSize * MBEMaxInflightBuffers, options: [])
        uniformBuffer.label = "uniforms"
    }

    @IBAction func selectedKernelChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: selectedKernel = gaussianBlurKernel
        case 1: selectedKernel = thresholdKernel
        case 2: selectedKernel = edgeKernel
        case 3: selectedKernel = saturationKernel
        default: break
        }
    }

    func updateBuffers() {
        // Copy positions and tex coords to the portion of the vertex buffer we'll be rendering from
        let vertBufferPtr = vertexBuffer.contents()
        let currentVertPtr = (vertBufferPtr + MBEVertexDataSize * bufferIndex)
        memcpy(currentVertPtr, vertexData, 24 * MemoryLayout<Float>.stride)

        // Build the uniforms for the current frame. If we were animating, we could do it here
        let aspect = Float(self.view.bounds.width / self.view.bounds.height)
        let fov = Float.pi / 2
        let projectionMatrix =  matrix_perspective_projection(aspect, fieldOfViewYRadians: fov, near: 0.1, far: 10.0)
        let viewMatrix = matrix_translation([0, 0, -2])
        var uniforms = MBEUniforms(modelViewProjectionMatrix: projectionMatrix * viewMatrix)

        // Copy uniform data into the portion of the uniform buffer we'll be rendering from
        let uniformBufferPtr = uniformBuffer.contents()
        let currentUniformPtr = (uniformBufferPtr + MBEUniformDataSize * bufferIndex)
        memcpy(currentUniformPtr, &uniforms, MemoryLayout<MBEUniforms>.stride)
    }
    
    func draw(in view: MTKView) {

        _ = inflightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        updateBuffers()
        
        let commandBuffer = commandQueue.makeCommandBuffer()!

        commandBuffer.addCompletedHandler{ [weak self] commandBuffer in
            if let strongSelf = self {
                strongSelf.inflightSemaphore.signal()
            }
        }

        // Update the saturation kernel's time-varying saturation factor
        saturationKernel.saturationFactor = Float(abs(sin(CACurrentMediaTime() * 2)))

        // Dispatch the current kernel to perform the selected image filter
        selectedKernel.encode(commandBuffer: commandBuffer,
            sourceTexture: kernelSourceTexture!,
            destinationTexture: kernelDestTexture!)

        if let renderPassDescriptor = view.currentRenderPassDescriptor, let currentDrawable = view.currentDrawable
        {
            let clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
            renderPassDescriptor.colorAttachments[0].clearColor = clearColor

            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            renderEncoder.label = "Main pass"

            renderEncoder.pushDebugGroup("Draw textured square")
            renderEncoder.setFrontFacing(.counterClockwise)
            renderEncoder.setCullMode(.back)

            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: MBEVertexDataSize * bufferIndex, index: 0)
            renderEncoder.setVertexBuffer(uniformBuffer, offset: MBEUniformDataSize * bufferIndex , index: 1)
            renderEncoder.setFragmentTexture(kernelDestTexture, index: 0)
            renderEncoder.setFragmentSamplerState(sampler, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

            renderEncoder.popDebugGroup()
            renderEncoder.endEncoding()
                
            commandBuffer.present(currentDrawable)
        }
        
        bufferIndex = (bufferIndex + 1) % MBEMaxInflightBuffers
        
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
}
