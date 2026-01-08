//
//  OffScreenRendererError.swift
//  LayerDemo
//
//  Created by BCL Device 5 on 5/1/26.
//

import UIKit
import AVFoundation

enum OffScreenRendererError: LocalizedError {
    case unknown
}

class OffScreenRenderer: NSObject {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let passDescriptor: MTLRenderPassDescriptor
    
    private let renderer: CARenderer
    private let startTime: CMTime
    
    init(device: MTLDevice? = nil) throws {
        let device = device ?? MTLCreateSystemDefaultDevice()
        
        guard
            let device,
            let commandQueue = device.makeCommandQueue(),
            let texture = device.generateOffScreenRendererTexture(size: CGSize(width: 100, height: 100))
        else {
            throw OffScreenRendererError.unknown
        }
        
        self.device = device
        self.commandQueue = commandQueue
        self.passDescriptor = MTLRenderPassDescriptor()
        
        self.renderer = CARenderer(mtlTexture: texture)
        self.startTime = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 600)
        
        passDescriptor.colorAttachments[0].storeAction = .store
        passDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        passDescriptor.colorAttachments[0].loadAction = .clear
    }
    
    func setLayer(_ parent: CALayer) throws {
        parent.beginTime = startTime.seconds
        renderer.layer = parent
        CATransaction.flush()
        CATransaction.commit()
        
        renderer.bounds = CGRect(origin: .zero, size: parent.bounds.size)
    }
    
    func renderCIImage(at time: CMTime) -> CIImage? {
        let texture = device.generateOffScreenRendererTexture(size: renderer.bounds.size)
        passDescriptor.colorAttachments[0].texture = texture
        
        guard
            let texture,
            let renderCommandBuffer = commandQueue.makeCommandBuffer(),
            let renderCommandEncoder = renderCommandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        else {
            return nil
        }
        
        renderCommandEncoder.endEncoding()
        renderCommandBuffer.commit()
        renderCommandBuffer.waitUntilCompleted()
        
        renderer.setDestination(texture)
        renderer.beginFrame(atTime: (startTime + time).seconds, timeStamp: nil)
        renderer.addUpdate(renderer.bounds)
        renderer.render()
        renderer.endFrame()
        
        guard
            let blitCommandBuffer = commandQueue.makeCommandBuffer(),
            let blitCommandEncoder = blitCommandBuffer.makeBlitCommandEncoder()
        else {
            return nil
        }
        
        blitCommandEncoder.endEncoding()
        blitCommandBuffer.commit()
        blitCommandBuffer.waitUntilCompleted()
        
        let ciImage = CIImage(
            mtlTexture: texture,
            options: [.colorSpace: CGColorSpace(name: CGColorSpace.sRGB)  as Any]
        )
        
        return ciImage
    }
    
    func renderCIImages(frameDuration: CMTime, timeRange: CMTimeRange) -> [CIImage] {
        var currentTime = timeRange.start
        var images: [CIImage] = []
        
        while currentTime < timeRange.end {
            if let image = renderCIImage(at: currentTime) {
                images.append(image)
            }
            currentTime = currentTime + frameDuration
        }
        
        return images
    }
}


extension MTLDevice {
    func generateOffScreenRendererTexture(size: CGSize) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm_srgb,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: false
        )
        
        textureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        return makeTexture(descriptor: textureDescriptor)
    }
}
