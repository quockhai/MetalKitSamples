//
//  Texturable.swift
//  MetalTextures
//
//  Created by quockhai on 2019/4/11.
//  Copyright © 2019 Polymath. All rights reserved.
//

import MetalKit

protocol Texturable {
    var texture: MTLTexture? {get set}
}

extension Texturable {
    func setTexture(device: MTLDevice, imageName: String) -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: device)
        
        var texture: MTLTexture? = nil
        
        let textureLoaderOptions: [MTKTextureLoader.Option: Any]
        if #available(iOS 10, *) {
//            let origin = NSString(string: MTKTextureLoader.Origin.bottomLeft)
            textureLoaderOptions = [MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.bottomLeft]
        } else {
            textureLoaderOptions = [:]
        }
        
        if let textureURL = Bundle.main.url(forResource: imageName, withExtension: nil) {
            do {
                
                texture = try textureLoader.newTexture(URL: textureURL, options: textureLoaderOptions)
            } catch let error {
                print("Texture error: \(error.localizedDescription)")
            }
        }
        
        return texture
    }
}
