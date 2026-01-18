//
//  StickerModel.swift
//  LayerDemo
//
//  Created by BCL Device 5 on 8/1/26.
//

import UIKit

// MARK: - Base Sticker Model
class StickerModel {
    let id: String
    var type: StickerType
    var layer: CALayer?
    var reflectionLayer: CALayer?
    var relativePosition: CGPoint
    var size: CGSize
    var rotation: CGFloat = 0
    var scale: CGFloat = 1.0
    var color: UIColor?
    var zIndex: Int = 0
    var isSelected: Bool = false
    var hasReflection: Bool = false
    var opacity: Float = 1.0
    
    // For lines
    var isHorizontal: Bool? = nil
    var initialEdge: Edge? = nil
    
    init(id: String = UUID().uuidString,
         type: StickerType,
         relativePosition: CGPoint,
         size: CGSize,
         color: UIColor? = nil,
         zIndex: Int = 0,
         hasReflection: Bool = false,
         opacity: Float = 1.0,
         isHorizontal: Bool? = nil,
         initialEdge: Edge? = nil) {
        self.id = id
        self.type = type
        self.relativePosition = relativePosition
        self.size = size
        self.color = color
        self.zIndex = zIndex
        self.hasReflection = hasReflection
        self.opacity = opacity
        self.isHorizontal = isHorizontal
        self.initialEdge = initialEdge
    }
}

// MARK: - Image Sticker Model
class ImageStickerModel: StickerModel {
    var image: UIImage
    
    init(id: String = UUID().uuidString,
         image: UIImage,
         relativePosition: CGPoint,
         size: CGSize,
         color: UIColor? = nil,
         zIndex: Int = 0,
         hasReflection: Bool = false,
         opacity: Float = 1.0) {
        self.image = image
        
        super.init(id: id,
                   type: .image,
                   relativePosition: relativePosition,
                   size: size,
                   color: color,
                   zIndex: zIndex,
                   hasReflection: hasReflection,
                   opacity: opacity)
    }
}

// MARK: - Text Sticker Model
class TextStickerModel: StickerModel {
    var text: String
    var fontSize: CGFloat
    var fontName: String?
    var textColor: UIColor
    var textAlignment: NSTextAlignment = .center
    
    init(id: String = UUID().uuidString,
         text: String,
         relativePosition: CGPoint,
         size: CGSize,
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
        
        super.init(id: id,
                   type: .text,
                   relativePosition: relativePosition,
                   size: size,
                   color: backgroundColor,
                   zIndex: zIndex,
                   hasReflection: hasReflection,
                   opacity: opacity)
    }
}

// MARK: - Shape Sticker Model
class ShapeStickerModel: StickerModel {
    var shapeType: ShapeType = .rectangle
    var cornerRadius: CGFloat = 0
    
    init(id: String = UUID().uuidString,
         relativePosition: CGPoint,
         size: CGSize,
         color: UIColor,
         shapeType: ShapeType = .rectangle,
         cornerRadius: CGFloat = 0,
         zIndex: Int = 0,
         hasReflection: Bool = false,
         opacity: Float = 1.0) {
        self.shapeType = shapeType
        self.cornerRadius = cornerRadius
        
        super.init(id: id,
                   type: .shape,
                   relativePosition: relativePosition,
                   size: size,
                   color: color,
                   zIndex: zIndex,
                   hasReflection: hasReflection,
                   opacity: opacity)
    }
}

// MARK: - Line Sticker Model
class LineStickerModel: StickerModel {
    var lineWidth: CGFloat = 12.0
    
    init(id: String = UUID().uuidString,
         relativePosition: CGPoint,
         size: CGSize,
         color: UIColor,
         isHorizontal: Bool? = nil,
         initialEdge: Edge? = nil,
         lineWidth: CGFloat = 12.0,
         zIndex: Int = 0,
         hasReflection: Bool = false,
         opacity: Float = 1.0) {
        self.lineWidth = lineWidth
        
        super.init(id: id,
                   type: .line,
                   relativePosition: relativePosition,
                   size: size,
                   color: color,
                   zIndex: zIndex,
                   hasReflection: hasReflection,
                   opacity: opacity,
                   isHorizontal: isHorizontal,
                   initialEdge: initialEdge)
    }
}

