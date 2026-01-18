//
//  StickerConfiguration.swift
//  LayerDemo
//
//  Created by BCL Device 5 on 8/1/26.
//

import UIKit

// MARK: - Base Configuration
class StickerConfiguration {
    var relativePosition: CGPoint
    var size: CGSize
    var color: UIColor?
    var zIndex: Int = 0
    var hasReflection: Bool = false
    var opacity: Float = 1.0
    
    init(relativePosition: CGPoint,
         size: CGSize,
         color: UIColor? = nil,
         zIndex: Int = 0,
         hasReflection: Bool = false,
         opacity: Float = 1.0) {
        self.relativePosition = relativePosition
        self.size = size
        self.color = color
        self.zIndex = zIndex
        self.hasReflection = hasReflection
        self.opacity = opacity
    }
}

// MARK: - Image Sticker Configuration
class ImageStickerConfiguration: StickerConfiguration {
    var image: UIImage
    
    init(relativePosition: CGPoint,
         size: CGSize,
         image: UIImage,
         color: UIColor? = nil,
         zIndex: Int = 0,
         hasReflection: Bool = false,
         opacity: Float = 1.0) {
        self.image = image
        super.init(relativePosition: relativePosition,
                   size: size,
                   color: color,
                   zIndex: zIndex,
                   hasReflection: hasReflection,
                   opacity: opacity)
    }
}

// MARK: - Text Sticker Configuration
class TextStickerConfiguration: StickerConfiguration {
    var text: String
    var fontSize: CGFloat
    var fontName: String?
    var textColor: UIColor
    var textAlignment: NSTextAlignment = .center
    
    init(relativePosition: CGPoint,
         size: CGSize,
         text: String,
         fontSize: CGFloat = 36,
         fontName: String? = nil,
         textColor: UIColor = .white,
         backgroundColor: UIColor? = nil,
         zIndex: Int = 10,
         hasReflection: Bool = true,
         opacity: Float = 1.0) {
        self.text = text
        self.fontSize = fontSize
        self.fontName = fontName
        self.textColor = textColor
        
        super.init(relativePosition: relativePosition,
                   size: size,
                   color: backgroundColor,
                   zIndex: zIndex,
                   hasReflection: hasReflection,
                   opacity: opacity)
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
         opacity: Float = 1.0) {
        self.shapeType = shapeType
        self.cornerRadius = cornerRadius
        
        super.init(relativePosition: relativePosition,
                   size: size,
                   color: color,
                   zIndex: zIndex,
                   hasReflection: hasReflection,
                   opacity: opacity)
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
         opacity: Float = 1.0) {
        self.isHorizontal = isHorizontal
        self.initialEdge = initialEdge
        self.lineWidth = lineWidth
        
        super.init(relativePosition: relativePosition,
                   size: size,
                   color: color,
                   zIndex: zIndex,
                   hasReflection: hasReflection,
                   opacity: opacity)
    }
}
