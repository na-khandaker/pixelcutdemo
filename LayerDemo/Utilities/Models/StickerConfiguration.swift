//
//  StickerConfiguration.swift
//  LayerDemo
//
//  Created by BCL Device 5 on 8/1/26.
//

import UIKit

class StickerConfiguration {
    var relativePosition: CGPoint
    var size: CGSize
    var relativeSize: CGSize?      // For relative sizing (0-1)
    var color: UIColor?
    var zIndex: Int = 0
    var hasReflection: Bool = false
    var opacity: Float = 1.0
    let animationType: AnimationType?
    let animationDuration: TimeInterval?
    let animationStartTime: TimeInterval?
    
    init(relativePosition: CGPoint,
         size: CGSize,
         relativeSize: CGSize? = nil,
         color: UIColor? = nil,
         zIndex: Int = 0,
         hasReflection: Bool = false,
         opacity: Float = 1.0,
         animationType: AnimationType? = nil,
         animationDuration: TimeInterval? = nil,
         animationStartTime: TimeInterval? = nil) {
        self.relativePosition = relativePosition
        self.size = size
        self.relativeSize = relativeSize
        self.color = color
        self.zIndex = zIndex
        self.hasReflection = hasReflection
        self.opacity = opacity
        self.animationType = animationType
        self.animationDuration = animationDuration
        self.animationStartTime = animationStartTime
    }
}

class TextStickerConfiguration: StickerConfiguration {
    var text: String
    var fontSize: CGFloat?          // Relative font size (0-1)
    var fontName: String?
    var textColor: UIColor
    var textAlignment: NSTextAlignment = .center
    
    init(relativePosition: CGPoint,
         size: CGSize,
         text: String,
         fontSize: CGFloat? = nil,
         fontName: String? = nil,
         textColor: UIColor = .white,
         backgroundColor: UIColor? = nil,
         zIndex: Int = 10,
         hasReflection: Bool = true,
         opacity: Float = 1.0,
         animationType: AnimationType? = nil,
         animationDuration: TimeInterval? = nil,
         animationStartTime: TimeInterval? = nil) {
        
        self.text = text
        self.fontSize = fontSize
        self.fontName = fontName
        self.textColor = textColor
        
        super.init(relativePosition: relativePosition,
                   size: size,
                   color: backgroundColor,
                   zIndex: zIndex,
                   hasReflection: hasReflection,
                   opacity: opacity,
                   animationType: animationType,
                   animationDuration: animationDuration,
                   animationStartTime: animationStartTime)
    }
}

class ImageStickerConfiguration: StickerConfiguration {
    var image: UIImage
    
    init(relativePosition: CGPoint,
         size: CGSize,
         image: UIImage,
         relativeSize: CGSize? = nil,
         color: UIColor? = nil,
         zIndex: Int = 0,
         hasReflection: Bool = false,
         opacity: Float = 1.0,
         animationType: AnimationType? = nil,
         animationDuration: TimeInterval? = nil,
         animationStartTime: TimeInterval? = nil) {
        self.image = image
        super.init(relativePosition: relativePosition,
                   size: size,
                   relativeSize: relativeSize,
                   color: color,
                   zIndex: zIndex,
                   hasReflection: hasReflection,
                   opacity: opacity,
                   animationType: animationType,
                   animationDuration: animationDuration,
                   animationStartTime: animationStartTime)
    }
}
// MARK: - Shape Sticker Configuration
class ShapeStickerConfiguration: StickerConfiguration {
    var shapeType: ShapeType = .rectangle
    var cornerRadius: CGFloat = 0
    
    init(relativePosition: CGPoint,
         size: CGSize,
         color: UIColor,
         shapeType: ShapeType = .rectangle,
         cornerRadius: CGFloat = 0,
         zIndex: Int = 0,
         hasReflection: Bool = false,
         opacity: Float = 1.0,
         animationType: AnimationType? = nil,
         animationDuration: TimeInterval? = nil) {
        self.shapeType = shapeType
        self.cornerRadius = cornerRadius
        
        super.init(relativePosition: relativePosition,
                   size: size,
                   color: color,
                   zIndex: zIndex,
                   hasReflection: hasReflection,
                   opacity: opacity,
                   animationType: animationType,
                   animationDuration: animationDuration)
    }
}

// MARK: - Line Sticker Configuration
class LineStickerConfiguration: StickerConfiguration {
    var isHorizontal: Bool?
    var initialEdge: Edge?
    var lineWidth: CGFloat = 12.0
    
    init(relativePosition: CGPoint,
         size: CGSize,
         color: UIColor,
         isHorizontal: Bool? = nil,
         initialEdge: Edge? = nil,
         lineWidth: CGFloat = 12.0,
         zIndex: Int = 0,
         hasReflection: Bool = false,
         opacity: Float = 1.0,
         animationType: AnimationType? = nil,
         animationDuration: TimeInterval? = nil) {
        self.isHorizontal = isHorizontal
        self.initialEdge = initialEdge
        self.lineWidth = lineWidth
        
        super.init(relativePosition: relativePosition,
                   size: size,
                   color: color,
                   zIndex: zIndex,
                   hasReflection: hasReflection,
                   opacity: opacity,
                   animationType: animationType,
                   animationDuration: animationDuration)
    }
}
