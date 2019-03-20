
import MetalPerformanceShaders

struct MBEImageSaturationParameters
{
    var offsetX: Int32 = 0
    var offsetY: Int32 = 0
    var clipOriginX: UInt32 = 0
    var clipOriginY: UInt32 = 0
    var clipMaxX: UInt32 = 0
    var clipMaxY: UInt32 = 0
    var saturation: Float = 1
    var padding: Float = 0
}

open class MBEImageSaturation : MPSUnaryImageKernel
{
    let MBEImageSaturationFunctionName = "image_saturation"

    open var saturationFactor: Float = 1.0

    var computePipeline: MTLComputePipelineState!
    var sampler: MTLSamplerState!

    open override var edgeMode: MPSImageEdgeMode {
        didSet {
            // Whenever the edge mode changes, we need to rebuild our sampler state
            if (edgeMode != oldValue) || (sampler == nil) {
                // MPS has its own notion of edge modes, so we translate into MTL-speak here
                let addressMode: MTLSamplerAddressMode = (edgeMode == .zero) ? .clampToZero : .clampToEdge
                let samplerDescriptor = MTLSamplerDescriptor()
                samplerDescriptor.magFilter = .nearest
                samplerDescriptor.minFilter = .nearest
                samplerDescriptor.rAddressMode = addressMode
                samplerDescriptor.sAddressMode = addressMode
                samplerDescriptor.tAddressMode = addressMode
                samplerDescriptor.normalizedCoordinates = false
                sampler = device.makeSamplerState(descriptor: samplerDescriptor)
            }
        }
    }

    public init(device: MTLDevice, saturationFactor: Float) {
        super.init(device: device)

        self.edgeMode = .zero

        self.saturationFactor = saturationFactor

        if let library = device.makeDefaultLibrary() {
            if let computeFunction = library.makeFunction(name: MBEImageSaturationFunctionName) {
                do {
                    try computePipeline = device.makeComputePipelineState(function: computeFunction)
                } catch {
                    print("Error occurred when compiling compute pipeline: \(error)")
                }
            } else {
                print("Failed to retrieve kernel function \(MBEImageSaturationFunctionName) from library")
            }
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func encode(commandBuffer: MTLCommandBuffer,
        sourceTexture: MTLTexture,
        destinationTexture destTexture: MTLTexture)
    {
        // We choose a fixed thread per threadgroup count here out of convenience, but could possibly
        // be more efficient by using a non-square threadgroup pattern like 32x16 or 16x32
        let threadsPerThreadgroup = MTLSizeMake(16, 16, 1)

        // It's possible for the provided clip rect to extend well beyond the bounds of the destination texture,
        // so we clip that region to the actual extents of the destination.
        let destRect = MBERegionClippedToSize(clipRect, size: MTLSizeMake(destTexture.width, destTexture.height, 0))

        var params = MBEImageSaturationParameters()
        params.offsetX = Int32(offset.x)
        params.offsetY = Int32(offset.y)
        params.clipOriginX = UInt32(destRect.origin.x)
        params.clipOriginY = UInt32(destRect.origin.y)
        params.clipMaxX = UInt32(destRect.origin.x + destRect.size.width)
        params.clipMaxY = UInt32(destRect.origin.y + destRect.size.height)
        params.saturation = saturationFactor

        // Determine how many threadgroups we need to dispatch to fully cover the destination region
        // There will almost certainly be some wasted threads except when both textures are neat
        // multiples of the thread-per-threadgroup size and the offset and clip region are agreeable.
        let widthInThreadgroups = (destRect.size.width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width
        let heightInThreadgroups = (destRect.size.height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height
        let threadgroupsPerGrid = MTLSizeMake(widthInThreadgroups, heightInThreadgroups, 1)

        // Set up and dispatch the work
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
        commandEncoder.pushDebugGroup("Dispatch image saturation adjustment kernel")
        commandEncoder.setComputePipelineState(computePipeline)
        commandEncoder.setTexture(sourceTexture, index: 0)
        commandEncoder.setTexture(destTexture, index: 1)
        commandEncoder.setSamplerState(sampler, index: 0)
        commandEncoder.setBytes(&params, length: MemoryLayout<MBEImageSaturationParameters>.stride, index: 0)
        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder.popDebugGroup()
        commandEncoder.endEncoding()
    }

    open override func encode(commandBuffer: MTLCommandBuffer,
        inPlaceTexture texture: UnsafeMutablePointer<MTLTexture>,
        fallbackCopyAllocator copyAllocator: MPSCopyAllocator?) -> Bool
    {
        guard let copyAllocator = copyAllocator else {
            // Can't operate in-place, so fail immediately if we weren't given a copy allocator
            return false
        }

        let sourceTexture = texture.pointee
        // Since we can't operate in-place, we have to invoke our copy allocator to get a suitable destination.
        // We could probably be much more efficient here by somehow keeping track of these textures in a pool
        // and reusing them, but that's a complicated proposition since we hand off ownership of them to our
        // caller.
        let destTexture = copyAllocator(self, commandBuffer, sourceTexture)
        encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: destTexture)
        texture.pointee = destTexture

        return true
    }
}
