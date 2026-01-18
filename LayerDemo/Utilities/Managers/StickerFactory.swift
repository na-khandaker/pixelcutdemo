//
//  StickerFactory.swift
//  LayerDemo
//
//  Created by BCL Device 5 on 8/1/26.
//

import UIKit

// MARK: - Protocol for Sticker Factory
protocol StickerFactoryProtocol {
    func createTextSticker(configuration: TextStickerConfiguration) -> TextStickerModel
    func createImageSticker(configuration: ImageStickerConfiguration) -> ImageStickerModel
    func createShapeSticker(configuration: ShapeStickerConfiguration) -> ShapeStickerModel
    func createLineSticker(configuration: LineStickerConfiguration) -> LineStickerModel
}

// MARK: - Sticker Factory
class StickerFactory: StickerFactoryProtocol {
    static let shared = StickerFactory()
    
    private init() {}
    
    func createTextSticker(configuration: TextStickerConfiguration) -> TextStickerModel {
        return TextStickerModel(
            text: configuration.text,
            relativePosition: configuration.relativePosition,
            size: configuration.size,
            fontSize: configuration.fontSize,
            fontName: configuration.fontName,
            textColor: configuration.textColor,
            backgroundColor: configuration.color,
            zIndex: configuration.zIndex,
            hasReflection: configuration.hasReflection,
            opacity: configuration.opacity
        )
    }
    
    func createImageSticker(configuration: ImageStickerConfiguration) -> ImageStickerModel {
        return ImageStickerModel(
            image: configuration.image,
            relativePosition: configuration.relativePosition,
            size: configuration.size,
            color: configuration.color,
            zIndex: configuration.zIndex,
            hasReflection: configuration.hasReflection,
            opacity: configuration.opacity
        )
    }
    
    func createShapeSticker(configuration: ShapeStickerConfiguration) -> ShapeStickerModel {
        return ShapeStickerModel(
            relativePosition: configuration.relativePosition,
            size: configuration.size,
            color: configuration.color ?? .systemPurple,
            shapeType: configuration.shapeType,
            cornerRadius: configuration.cornerRadius,
            zIndex: configuration.zIndex,
            hasReflection: configuration.hasReflection,
            opacity: configuration.opacity
        )
    }
    
    func createLineSticker(configuration: LineStickerConfiguration) -> LineStickerModel {
        let isHorizontal = configuration.isHorizontal ?? (configuration.size.height < configuration.size.width)
        
        return LineStickerModel(
            relativePosition: configuration.relativePosition,
            size: configuration.size,
            color: configuration.color ?? getColorForEdge(configuration.initialEdge),
            isHorizontal: isHorizontal,
            initialEdge: configuration.initialEdge,
            lineWidth: configuration.lineWidth,
            zIndex: configuration.zIndex,
            hasReflection: configuration.hasReflection,
            opacity: configuration.opacity
        )
    }
    
    private func getColorForEdge(_ edge: Edge?) -> UIColor {
        guard let edge = edge else { return .systemGray }
        
        switch edge {
        case .top: return .systemBlue
        case .bottom: return .systemRed
        case .left: return .systemGreen
        case .right: return .systemOrange
        }
    }
}
