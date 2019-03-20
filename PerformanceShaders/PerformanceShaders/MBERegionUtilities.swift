import Metal
import MetalPerformanceShaders

func MBEOriginEqualToOrigin(_ a: MTLOrigin, _ b: MTLOrigin) -> Bool {
    return a.x == b.x && a.y == b.y && a.z == b.z
}

func MBESizeEqualToSize(_ a: MTLSize, _ b: MTLSize) -> Bool {
    return a.width == b.width && a.height == b.height && a.depth == b.depth
}

/// Returns true iff two regions compare as member-wise equal
public func MBERegionEqualToRegion(_ a: MTLRegion, b: MTLRegion) -> Bool {
    return MBEOriginEqualToOrigin(a.origin, b.origin) && MBESizeEqualToSize(a.size, b.size)
}

/// Reshapes the provided region so it fits in a region with the provided size
public func MBERegionClippedToSize(_ region: MTLRegion, size: MTLSize) -> MTLRegion {
    if MBERegionEqualToRegion(region, b: MPSRectNoClip) {
        return MTLRegionMake3D(0, 0, 0, size.width, size.height, size.depth)
    } else {
        var clippedRegion = region

        if clippedRegion.origin.x < 0 {
            clippedRegion.size.width -= clippedRegion.origin.x
            clippedRegion.origin.x = 0
        }

        if clippedRegion.origin.y < 0 {
            clippedRegion.size.height -= clippedRegion.origin.y
            clippedRegion.origin.y = 0
        }

        if clippedRegion.origin.z < 0 {
            clippedRegion.size.depth -= clippedRegion.origin.z
            clippedRegion.origin.z = 0
        }

        if clippedRegion.origin.x + clippedRegion.size.width > size.width {
            clippedRegion.size.width = size.width - clippedRegion.origin.x
        }

        if clippedRegion.origin.y + clippedRegion.size.height > size.height {
            clippedRegion.size.height = size.height - clippedRegion.origin.y
        }

        if clippedRegion.origin.z + clippedRegion.size.depth > size.depth {
            clippedRegion.size.depth = size.depth - clippedRegion.origin.z
        }
        
        return clippedRegion
    }
}
