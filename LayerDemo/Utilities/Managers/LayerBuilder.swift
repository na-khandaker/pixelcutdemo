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

// MARK: - Layer Builder with Reflection Support
class LayerBuilder: LayerBuilderProtocol {
    static let shared = LayerBuilder()
    
    private init() {}
    
    func createLayer(from sticker: StickerModel) -> CALayer {
        let baseLayer = createBaseLayer(from: sticker)
        
        switch sticker.type {
        case .text:
            return createTextLayer(from: sticker as! TextStickerModel)
        case .line:
            return createLineLayer(from: sticker as! LineStickerModel)
        case .image:
            return createImageLayer(from: sticker as! ImageStickerModel)
        case .shape:
            return createShapeLayer(from: sticker as! ShapeStickerModel)
        }
    }
    
    // MARK: - Base Layer Creation
    private func createBaseLayer(from sticker: StickerModel) -> CALayer {
        let baseLayer = CALayer()
        
        // Apply common properties
        baseLayer.position = sticker.position
        baseLayer.bounds.size = sticker.size
        baseLayer.transform = CATransform3DMakeRotation(sticker.rotation, 0, 0, 1)
        baseLayer.transform = CATransform3DScale(baseLayer.transform, sticker.scale, sticker.scale, 1)
        baseLayer.zPosition = CGFloat(sticker.zIndex)
        baseLayer.opacity = sticker.opacity
        
        // Apply background color if exists
        if let color = sticker.color {
            baseLayer.backgroundColor = color.cgColor
        }
        
        return baseLayer
    }
    
    // MARK: - Text Layer Creation
//    private func createTextLayer(from sticker: TextStickerModel) -> CALayer {
//        let textLayer = CATextLayer()
//        
//        // Configure text properties
//        textLayer.string = sticker.text
//        textLayer.font = CTFontCreateWithName((sticker.fontName ?? "Helvetica") as CFString, sticker.fontSize, nil)
//        textLayer.fontSize = sticker.fontSize
//        textLayer.foregroundColor = sticker.textColor.cgColor
//        textLayer.alignmentMode = convertToCATextLayerAlignmentMode(sticker.textAlignment)
//        textLayer.isWrapped = true
//        textLayer.contentsScale = UIScreen.main.scale
//        
//        // CRITICAL FIX: Clip text to bounds
//        textLayer.masksToBounds = true
//        
//        // Calculate text size to fit within bounds
//        let textSize = calculateTextSize(for: sticker.text,
//                                         font: UIFont(name: sticker.fontName ?? "Helvetica", size: sticker.fontSize) ?? UIFont.systemFont(ofSize: sticker.fontSize),
//                                         maxWidth: sticker.size.width)
//        
//        // Adjust frame to ensure text fits
//        let textFrame = CGRect(x: 0,
//                              y: (sticker.size.height - textSize.height) / 2,
//                              width: sticker.size.width,
//                              height: min(textSize.height, sticker.size.height))
//        
//        textLayer.frame = textFrame
//        
//        // Apply base properties
//        let baseLayer = createBaseLayer(from: sticker)
//        
//        // Create container layer to hold text and reflection
//        let containerLayer = CALayer()
//        containerLayer.frame = baseLayer.bounds
//        containerLayer.position = baseLayer.position
//        containerLayer.transform = baseLayer.transform
//        containerLayer.zPosition = baseLayer.zPosition
//        containerLayer.opacity = baseLayer.opacity
//        
//        // CRITICAL: Also clip container layer
//        containerLayer.masksToBounds = true
//        
//        if let color = sticker.color {
//            containerLayer.backgroundColor = color.cgColor
//        }
//        
//        // Add text layer to container
//        containerLayer.addSublayer(textLayer)
//        
//        // Add reflection if needed
//        if sticker.hasReflection {
//            addReflectionLayer(to: containerLayer, sticker: sticker)
//        }
//        
//        // Store references
//        sticker.layer = containerLayer
//        sticker.reflectionLayer = containerLayer.sublayers?.last
//        
//        return containerLayer
//    }
    
    private func calculateTextSize(for text: String, font: UIFont, maxWidth: CGFloat) -> CGSize {
        let constraintRect = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [.font: font],
                                            context: nil)
        return CGSize(width: ceil(boundingBox.width),
                      height: ceil(boundingBox.height))
    }
    
    // MARK: - Reflection Layer
//    private func addReflectionLayer(to containerLayer: CALayer, sticker: StickerModel) {
//        guard let originalLayer = containerLayer.sublayers?.first else { return }
//        
//        // Create reflection layer
//        let reflectionLayer = CALayer()
//        reflectionLayer.contents = originalLayer.contents
//        reflectionLayer.frame = originalLayer.frame
//        reflectionLayer.contentsScale = originalLayer.contentsScale
//        reflectionLayer.transform = CATransform3DMakeScale(1, -1, 1)
//        reflectionLayer.opacity = 0.3
//        
//        // Position reflection below original
//        let reflectionHeight = containerLayer.bounds.height * 0.3
//        reflectionLayer.frame.origin.y = containerLayer.bounds.height
//        
//        // Create gradient mask for fade effect
//        let gradientMask = CAGradientLayer()
//        gradientMask.frame = CGRect(x: 0, y: 0,
//                                   width: reflectionLayer.bounds.width,
//                                   height: reflectionHeight)
//        gradientMask.colors = [
//            UIColor.white.withAlphaComponent(0.5).cgColor,
//            UIColor.white.withAlphaComponent(0.0).cgColor
//        ]
//        gradientMask.locations = [0.0, 1.0]
//        gradientMask.startPoint = CGPoint(x: 0.5, y: 0.0)
//        gradientMask.endPoint = CGPoint(x: 0.5, y: 1.0)
//        
//        reflectionLayer.mask = gradientMask
//        containerLayer.addSublayer(reflectionLayer)
//    }
    
    // MARK: - Image Layer Creation
//    private func createImageLayer(from sticker: ImageStickerModel) -> CALayer {
//        let imageLayer = CALayer()
//        
//        // Configure image
//        imageLayer.contents = sticker.image.cgImage
//        imageLayer.contentsGravity = .resizeAspectFill
//        imageLayer.masksToBounds = true
//        
//        // Apply base properties
//        let baseLayer = createBaseLayer(from: sticker)
//        imageLayer.frame = baseLayer.bounds
//        imageLayer.position = baseLayer.position
//        imageLayer.transform = baseLayer.transform
//        imageLayer.zPosition = baseLayer.zPosition
//        imageLayer.opacity = baseLayer.opacity
//        
//        // Add reflection if needed
//        if sticker.hasReflection {
//            let containerLayer = CALayer()
//            containerLayer.frame = baseLayer.bounds
//            containerLayer.position = baseLayer.position
//            containerLayer.transform = baseLayer.transform
//            containerLayer.zPosition = baseLayer.zPosition
//            
//            containerLayer.addSublayer(imageLayer)
//            addReflectionLayer(to: containerLayer, sticker: sticker)
//            
//            sticker.layer = containerLayer
//            sticker.reflectionLayer = containerLayer.sublayers?.last
//            return containerLayer
//        }
//        
//        sticker.layer = imageLayer
//        return imageLayer
//    }
    
    // MARK: - Shape Layer Creation
//    private func createShapeLayer(from sticker: ShapeStickerModel) -> CALayer {
//        let shapeLayer = CALayer()
//        
//        // Configure shape
//        shapeLayer.cornerRadius = sticker.cornerRadius
//        
//        if sticker.shapeType == .circle {
//            shapeLayer.cornerRadius = min(sticker.size.width, sticker.size.height) / 2
//        }
//        
//        // Apply base properties
//        let baseLayer = createBaseLayer(from: sticker)
//        shapeLayer.frame = baseLayer.bounds
//        shapeLayer.position = baseLayer.position
//        shapeLayer.transform = baseLayer.transform
//        shapeLayer.zPosition = baseLayer.zPosition
//        shapeLayer.opacity = baseLayer.opacity
//        shapeLayer.backgroundColor = sticker.color?.cgColor
//        
//        // Add reflection if needed
//        if sticker.hasReflection {
//            let containerLayer = CALayer()
//            containerLayer.frame = baseLayer.bounds
//            containerLayer.position = baseLayer.position
//            containerLayer.transform = baseLayer.transform
//            containerLayer.zPosition = baseLayer.zPosition
//            
//            containerLayer.addSublayer(shapeLayer)
//            addReflectionLayer(to: containerLayer, sticker: sticker)
//            
//            sticker.layer = containerLayer
//            sticker.reflectionLayer = containerLayer.sublayers?.last
//            return containerLayer
//        }
//        
//        sticker.layer = shapeLayer
//        return shapeLayer
//    }
    
    // MARK: - Line Layer Creation
    private func createLineLayer(from sticker: LineStickerModel) -> CALayer {
        let lineLayer = CALayer()
        
        // Create line with proper dimensions
        var displaySize = sticker.size
        
        // For edge lines, ensure they're visible
        if let edge = sticker.initialEdge {
            switch edge {
            case .top, .bottom:
                displaySize.height = sticker.lineWidth
                displaySize.width = sticker.size.width > 0 ? sticker.size.width : 1.0
            case .left, .right:
                displaySize.width = sticker.lineWidth
                displaySize.height = sticker.size.height > 0 ? sticker.size.height : 1.0
            }
        }
        
        lineLayer.frame = CGRect(origin: .zero, size: displaySize)
        lineLayer.backgroundColor = sticker.color?.cgColor
        
        // Set anchor point based on initial edge if available
        if let edge = sticker.initialEdge {
            switch edge {
            case .top:
                lineLayer.anchorPoint = CGPoint(x: 0, y: 0.5)
            case .bottom:
                lineLayer.anchorPoint = CGPoint(x: 1, y: 0.5)
            case .left:
                lineLayer.anchorPoint = CGPoint(x: 0.5, y: 0)
            case .right:
                lineLayer.anchorPoint = CGPoint(x: 0.5, y: 1)
            }
        } else {
            lineLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        }
        
        // Apply base properties
        let baseLayer = createBaseLayer(from: sticker)
        lineLayer.position = baseLayer.position
        lineLayer.transform = baseLayer.transform
        lineLayer.zPosition = baseLayer.zPosition
        lineLayer.opacity = baseLayer.opacity
        
        sticker.layer = lineLayer
        return lineLayer
    }
    
    // MARK: - Animation Methods
//    func applyAnimation(to layer: CALayer, animationType: AnimationType, duration: TimeInterval) {
//        switch animationType {
//        case .RevealUp, .RevealDown, .RevealLeft, .RevealRight:
//            applyRevealAnimation(to: layer, type: animationType, duration: duration)
//        case .DriftUp, .DriftDown, .DriftLeft, .DriftRight:
//            applyDriftAnimation(to: layer, type: animationType, duration: duration)
//        case .Fade:
//            applyFadeAnimation(to: layer, duration: duration)
//        case .Scale:
//            applyScaleAnimation(to: layer, duration: duration)
//        default:
//            break
//        }
//    }
    
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
    private func convertToCATextLayerAlignmentMode(_ alignment: NSTextAlignment) -> CATextLayerAlignmentMode {
        switch alignment {
        case .left:
            return .left
        case .center:
            return .center
        case .right:
            return .right
        case .justified:
            return .justified
        case .natural:
            return .natural
        @unknown default:
            return .center
        }
    }
    
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
        let offset: CGFloat = 100
        
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

extension LayerBuilder {
    // MARK: - Text Layer Creation (CORRECTED)
    private func createTextLayer(from sticker: TextStickerModel) -> CALayer {
        let textLayer = CATextLayer()
        
        // Configure text properties
        textLayer.string = sticker.text
        textLayer.font = CTFontCreateWithName((sticker.fontName ?? "Helvetica") as CFString, sticker.fontSize, nil)
        textLayer.fontSize = sticker.fontSize
        textLayer.foregroundColor = sticker.textColor.cgColor
        textLayer.alignmentMode = convertToCATextLayerAlignmentMode(sticker.textAlignment)
        textLayer.isWrapped = true
        textLayer.contentsScale = UIScreen.main.scale
        
        // Calculate text size to fit within bounds
        let textSize = calculateTextSize(for: sticker.text,
                                         font: UIFont(name: sticker.fontName ?? "Helvetica", size: sticker.fontSize) ?? UIFont.systemFont(ofSize: sticker.fontSize),
                                         maxWidth: sticker.size.width)
        
        // Adjust frame to ensure text fits
        let textFrame = CGRect(x: 0,
                              y: (sticker.size.height - textSize.height) / 2,
                              width: sticker.size.width,
                              height: min(textSize.height, sticker.size.height))
        
        textLayer.frame = textFrame
        
        // Apply base properties to container layer
        let containerLayer = CALayer()
        containerLayer.frame = CGRect(origin: .zero, size: sticker.size)
        containerLayer.position = sticker.position
        containerLayer.bounds.size = sticker.size
        containerLayer.transform = CATransform3DMakeRotation(sticker.rotation, 0, 0, 1)
        containerLayer.transform = CATransform3DScale(containerLayer.transform, sticker.scale, sticker.scale, 1)
        containerLayer.zPosition = CGFloat(sticker.zIndex)
        containerLayer.opacity = sticker.opacity
        
        // Apply background color if exists
        if let color = sticker.color {
            containerLayer.backgroundColor = color.cgColor
        }
        
        // CRITICAL: Container should NOT mask to bounds for reflection
        containerLayer.masksToBounds = false
        
        // Add text layer to container
        containerLayer.addSublayer(textLayer)
        
        // Store reference - reflection will be handled by ViewController
        sticker.layer = containerLayer
        
        return containerLayer
    }

    // MARK: - Image Layer Creation (CORRECTED)
    private func createImageLayer(from sticker: ImageStickerModel) -> CALayer {
        let imageLayer = CALayer()
        
        // Configure image
        imageLayer.contents = sticker.image.cgImage
        imageLayer.contentsGravity = .resizeAspectFill
        imageLayer.masksToBounds = true
        imageLayer.frame = CGRect(origin: .zero, size: sticker.size)
        
        // Apply base properties
        let containerLayer = CALayer()
        containerLayer.frame = CGRect(origin: .zero, size: sticker.size)
        containerLayer.position = sticker.position
        containerLayer.bounds.size = sticker.size
        containerLayer.transform = CATransform3DMakeRotation(sticker.rotation, 0, 0, 1)
        containerLayer.transform = CATransform3DScale(containerLayer.transform, sticker.scale, sticker.scale, 1)
        containerLayer.zPosition = CGFloat(sticker.zIndex)
        containerLayer.opacity = sticker.opacity
        
        // CRITICAL: Container should NOT mask to bounds for reflection
        containerLayer.masksToBounds = false
        
        containerLayer.addSublayer(imageLayer)
        
        // Store reference
        sticker.layer = containerLayer
        
        return containerLayer
    }

    // MARK: - Shape Layer Creation (CORRECTED)
    private func createShapeLayer(from sticker: ShapeStickerModel) -> CALayer {
        let shapeLayer = CALayer()
        
        // Configure shape
        shapeLayer.cornerRadius = sticker.cornerRadius
        
        if sticker.shapeType == .circle {
            shapeLayer.cornerRadius = min(sticker.size.width, sticker.size.height) / 2
        }
        
        shapeLayer.frame = CGRect(origin: .zero, size: sticker.size)
        shapeLayer.backgroundColor = sticker.color?.cgColor
        
        // Apply base properties
        let containerLayer = CALayer()
        containerLayer.frame = CGRect(origin: .zero, size: sticker.size)
        containerLayer.position = sticker.position
        containerLayer.bounds.size = sticker.size
        containerLayer.transform = CATransform3DMakeRotation(sticker.rotation, 0, 0, 1)
        containerLayer.transform = CATransform3DScale(containerLayer.transform, sticker.scale, sticker.scale, 1)
        containerLayer.zPosition = CGFloat(sticker.zIndex)
        containerLayer.opacity = sticker.opacity
        
        // CRITICAL: Container should NOT mask to bounds for reflection
        containerLayer.masksToBounds = false
        
        containerLayer.addSublayer(shapeLayer)
        
        // Store reference
        sticker.layer = containerLayer
        
        return containerLayer
    }
}

// MARK: - Animation Methods in LayerBuilder (Updated)
extension LayerBuilder {
    func applyAnimation(to layer: CALayer, animationType: AnimationType, duration: TimeInterval) {
        // Check if this is a reflection layer
        let isReflectionLayer = layer.name == "reflection_layer"
        
        switch animationType {
        case .RevealUp, .RevealDown, .RevealLeft, .RevealRight:
            applyRevealAnimation(to: layer, type: animationType, duration: duration, isReflectionLayer: isReflectionLayer)
        case .DriftUp, .DriftDown, .DriftLeft, .DriftRight:
            applyDriftAnimation(to: layer, type: animationType, duration: duration, isReflectionLayer: isReflectionLayer)
        case .Fade:
            applyFadeAnimation(to: layer, duration: duration)
        case .Scale:
            applyScaleAnimation(to: layer, duration: duration, isReflectionLayer: isReflectionLayer)
        default:
            break
        }
    }
    
    private func applyRevealAnimation(to layer: CALayer, type: AnimationType, duration: TimeInterval, isReflectionLayer: Bool = false) {
        guard let maskLayer = createMaskLayer(for: type, size: layer.bounds.size) else { return }
        layer.mask = maskLayer
        
        // For reflection layers, we might need to adjust the animation
        var animationType = type
        if isReflectionLayer {
            // For reflection, we might want to reverse certain animations
            // This depends on your desired effect
            switch type {
            case .RevealUp:
                animationType = .RevealDown
            case .RevealDown:
                animationType = .RevealUp
            // For left/right reveals, keep the same direction
            default:
                break
            }
        }
        
        let animation = CABasicAnimation(keyPath: getRevealKeyPath(for: animationType))
        animation.fromValue = 0
        animation.toValue = getRevealToValue(for: animationType, layer: layer)
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        maskLayer.add(animation, forKey: "revealAnimation")
    }
    
    private func applyDriftAnimation(to layer: CALayer, type: AnimationType, duration: TimeInterval, isReflectionLayer: Bool = false) {
        var animationType = type
        
        // For reflection layers, adjust drift direction if needed
        if isReflectionLayer {
            switch type {
            case .DriftUp:
                animationType = .DriftDown
            case .DriftDown:
                animationType = .DriftUp
            case .DriftLeft:
                animationType = .DriftRight
            case .DriftRight:
                animationType = .DriftLeft
            default:
                break
            }
        }
        
        let animation = CABasicAnimation(keyPath: getDriftKeyPath(for: animationType))
        animation.fromValue = getDriftFromValue(for: animationType, layer: layer)
        animation.toValue = getDriftToValue(for: animationType, layer: layer)
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        layer.add(animation, forKey: "driftAnimation")
    }
    
//    private func applyFadeAnimation(to layer: CALayer, duration: TimeInterval) {
//        let animation = CABasicAnimation(keyPath: "opacity")
//        animation.fromValue = 0.0
//        animation.toValue = layer.opacity // Use the layer's current opacity
//        animation.duration = duration
//        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//        animation.fillMode = .forwards
//        animation.isRemovedOnCompletion = false
//        
//        layer.add(animation, forKey: "fadeAnimation")
//    }
    
    private func applyScaleAnimation(to layer: CALayer, duration: TimeInterval, isReflectionLayer: Bool = false) {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        
        // For reflection layers, we might want to start from a different scale
        if isReflectionLayer {
            animation.fromValue = 0.5
            animation.toValue = 1.0
        } else {
            animation.fromValue = 0.5
            animation.toValue = 1.0
        }
        
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        layer.add(animation, forKey: "scaleAnimation")
    }
}
