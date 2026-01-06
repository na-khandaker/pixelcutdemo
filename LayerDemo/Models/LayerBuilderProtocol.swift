//
//  LayerBuilderProtocol.swift
//  LayerDemo
//
//  Created by BCL Device 5 on 6/1/26.
//
import UIKit

// MARK: - Protocol for Layer Builder
protocol LayerBuilderProtocol {
    func createLayer(from sticker: StickerModel) -> CALayer
    func applyAnimation(to layer: CALayer, animationType: AnimationType, duration: TimeInterval)
}

// MARK: - Layer Builder
class LayerBuilder: LayerBuilderProtocol {
    static let shared = LayerBuilder()
    
    private init() {}
    
    func createLayer(from sticker: StickerModel) -> CALayer {
        switch sticker.type {
        case .line:
            return createLineLayer(from: sticker)
        case .image:
            return createImageLayer(from: sticker)
        case .shape:
            return createShapeLayer(from: sticker)
        }
    }
    
    private func createLineLayer(from sticker: StickerModel) -> CALayer {
        let layer = CALayer()
        
        // Create line with proper dimensions
        var displaySize = sticker.size
        
        // For edge lines, ensure they're visible
        if let edge = sticker.initialEdge {
            switch edge {
            case .top, .bottom:
                displaySize.height = 12.0
                displaySize.width = sticker.size.width > 0 ? sticker.size.width : 1.0
            case .left, .right:
                displaySize.width = 12.0
                displaySize.height = sticker.size.height > 0 ? sticker.size.height : 1.0
            }
        }
        
        layer.frame = CGRect(origin: .zero, size: displaySize)
        layer.backgroundColor = sticker.color?.cgColor
        
        // Set anchor point based on initial edge if available
        if let edge = sticker.initialEdge {
            switch edge {
            case .top:
                layer.anchorPoint = CGPoint(x: 0, y: 0.5)
            case .bottom:
                layer.anchorPoint = CGPoint(x: 1, y: 0.5)
            case .left:
                layer.anchorPoint = CGPoint(x: 0.5, y: 0)
            case .right:
                layer.anchorPoint = CGPoint(x: 0.5, y: 1)
            }
        } else {
            layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        }
        
        layer.position = sticker.position
        layer.transform = CATransform3DMakeRotation(sticker.rotation, 0, 0, 1)
        layer.transform = CATransform3DScale(layer.transform, sticker.scale, sticker.scale, 1)
        
        return layer
    }
    
    private func createImageLayer(from sticker: StickerModel) -> CALayer {
        let layer = CALayer()
        layer.frame = CGRect(origin: .zero, size: sticker.size)
        
        if let cgImage = sticker.image?.cgImage {
            layer.contents = cgImage
            layer.contentsGravity = .resizeAspectFill
        } else {
            layer.backgroundColor = UIColor.gray.cgColor
        }
        
        layer.masksToBounds = true
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.position = sticker.position
        layer.transform = CATransform3DMakeRotation(sticker.rotation, 0, 0, 1)
        layer.transform = CATransform3DScale(layer.transform, sticker.scale, sticker.scale, 1)
        
        return layer
    }
    
    private func createShapeLayer(from sticker: StickerModel) -> CALayer {
        let layer = CALayer()
        layer.frame = CGRect(origin: .zero, size: sticker.size)
        layer.backgroundColor = sticker.color?.cgColor
        layer.cornerRadius = min(sticker.size.width, sticker.size.height) / 4
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.position = sticker.position
        layer.transform = CATransform3DMakeRotation(sticker.rotation, 0, 0, 1)
        layer.transform = CATransform3DScale(layer.transform, sticker.scale, sticker.scale, 1)
        
        return layer
    }
    
    func applyAnimation(to layer: CALayer, animationType: AnimationType, duration: TimeInterval) {
        switch animationType {
        case .RevealUp, .RevealDown, .RevealLeft, .RevealRight:
            applyRevealAnimation(to: layer, type: animationType, duration: duration)
        case .DriftUp, .DriftDown, .DriftLeft, .DriftRight:
            applyDriftAnimation(to: layer, type: animationType, duration: duration)
        case .Fade:
            applyFadeAnimation(to: layer, duration: duration)
        case .Scale:
            applyScaleAnimation(to: layer, duration: duration)
        default:
            break
        }
    }
    
    private func applyRevealAnimation(to layer: CALayer, type: AnimationType, duration: TimeInterval) {
        guard let maskLayer = createMaskLayer(for: type, size: layer.bounds.size) else { return }
        layer.mask = maskLayer
        
        let animation = CABasicAnimation(keyPath: getRevealKeyPath(for: type))
        animation.fromValue = 0
        animation.toValue = getRevealToValue(for: type, layer: layer)
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        maskLayer.add(animation, forKey: "revealAnimation")
    }
    
    private func applyDriftAnimation(to layer: CALayer, type: AnimationType, duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath: getDriftKeyPath(for: type))
        animation.fromValue = getDriftFromValue(for: type, layer: layer)
        animation.toValue = getDriftToValue(for: type, layer: layer)
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        layer.add(animation, forKey: "driftAnimation")
    }
    
    private func applyFadeAnimation(to layer: CALayer, duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        layer.opacity = 1.0
        layer.add(animation, forKey: "fadeAnimation")
    }
    
    private func applyScaleAnimation(to layer: CALayer, duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 0.5
        animation.toValue = 1.0
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        layer.transform = CATransform3DScale(layer.transform, 1.0, 1.0, 1.0)
        layer.add(animation, forKey: "scaleAnimation")
    }
    
    // MARK: - Helper Methods
    
    private func createMaskLayer(for animationType: AnimationType, size: CGSize) -> CALayer? {
        let maskLayer = CALayer()
        maskLayer.backgroundColor = UIColor.black.cgColor
        
        var anchorPoint: CGPoint
        var position: CGPoint
        
        switch animationType {
        case .RevealDown:
            anchorPoint = CGPoint(x: 0.5, y: 0)
            position = CGPoint(x: size.width / 2, y: 0)
        case .RevealUp:
            anchorPoint = CGPoint(x: 0.5, y: 1)
            position = CGPoint(x: size.width / 2, y: size.height)
        case .RevealLeft:
            anchorPoint = CGPoint(x: 1, y: 0.5)
            position = CGPoint(x: size.width, y: size.height / 2)
        case .RevealRight:
            anchorPoint = CGPoint(x: 0.0, y: 0.5)
            position = CGPoint(x: 0, y: size.height / 2)
        default:
            return nil
        }
        
        maskLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        maskLayer.anchorPoint = anchorPoint
        maskLayer.position = position
        
        return maskLayer
    }
    
    private func getRevealKeyPath(for animationType: AnimationType) -> String {
        switch animationType {
        case .RevealDown, .RevealUp:
            return "bounds.size.height"
        case .RevealLeft, .RevealRight:
            return "bounds.size.width"
        default:
            return ""
        }
    }
    
    private func getRevealToValue(for animationType: AnimationType, layer: CALayer) -> CGFloat {
        switch animationType {
        case .RevealDown, .RevealUp:
            return layer.bounds.height
        case .RevealLeft, .RevealRight:
            return layer.bounds.width
        default:
            return 0
        }
    }
    
    private func getDriftKeyPath(for animationType: AnimationType) -> String {
        switch animationType {
        case .DriftUp, .DriftDown:
            return "position.y"
        case .DriftLeft, .DriftRight:
            return "position.x"
        default:
            return ""
        }
    }
    
    private func getDriftFromValue(for animationType: AnimationType, layer: CALayer) -> CGFloat {
        let offset: CGFloat = 1000
        
        switch animationType {
        case .DriftUp:
            return layer.position.y + offset
        case .DriftDown:
            return layer.position.y - offset
        case .DriftLeft:
            return layer.position.x + offset
        case .DriftRight:
            return layer.position.x - offset
        default:
            return 0
        }
    }
    
    private func getDriftToValue(for animationType: AnimationType, layer: CALayer) -> CGFloat {
        switch animationType {
        case .DriftUp, .DriftDown:
            return layer.position.y
        case .DriftLeft, .DriftRight:
            return layer.position.x
        default:
            return 0
        }
    }
}
