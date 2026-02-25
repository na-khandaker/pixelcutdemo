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
            fontSize: configuration.fontSize ?? 18,
            fontName: configuration.fontName,
            textColor: configuration.textColor,
            backgroundColor: configuration.color,
            zIndex: configuration.zIndex,
            hasReflection: configuration.hasReflection,
            opacity: configuration.opacity,
            animationType: configuration.animationType,
            animationDuration: configuration.animationDuration
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
            opacity: configuration.opacity,
            animationType: configuration.animationType,
            animationDuration: configuration.animationDuration
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
            opacity: configuration.opacity,
            animationType: configuration.animationType,
            animationDuration: configuration.animationDuration
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
            opacity: configuration.opacity,
            animationType: configuration.animationType,
            animationDuration: configuration.animationDuration
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

extension StickerFactory {
    func createTextSticker(configuration: TextStickerConfiguration, canvasSize: CGSize) -> TextStickerModel {
        // Calculate absolute font size from relative size
        let relativeFontSize = configuration.fontSize ?? 0.05
        let absoluteFontSize = relativeFontSize * min(canvasSize.width, canvasSize.height)
        
        // Calculate text bounding box
        let textSize = calculateTextSize(
            text: configuration.text,
            fontName: configuration.fontName ?? "Helvetica",
            fontSize: absoluteFontSize,
            maxWidth: canvasSize.width * 0.8
        )
        
        return TextStickerModel(
            text: configuration.text,
            relativePosition: configuration.relativePosition,
            size: textSize,
            fontSize: absoluteFontSize,
            fontName: configuration.fontName,
            textColor: configuration.textColor,
            backgroundColor: configuration.color,
            zIndex: configuration.zIndex,
            hasReflection: configuration.hasReflection,
            opacity: configuration.opacity,
            animationType: configuration.animationType,
            animationDuration: configuration.animationDuration,
            animationStartTime: configuration.animationStartTime
        )
    }
    
    func createImageSticker(configuration: ImageStickerConfiguration, canvasSize: CGSize) -> ImageStickerModel {
        // Calculate absolute size from relative if needed
        var size = configuration.size
        
        if size == .zero, let relativeSize = configuration.relativeSize {
            size = CGSize(
                width: relativeSize.width * canvasSize.width,
                height: relativeSize.height * canvasSize.height
            )
        }
        
        return ImageStickerModel(
            image: configuration.image,
            relativePosition: configuration.relativePosition,
            size: size,
            color: configuration.color,
            zIndex: configuration.zIndex,
            hasReflection: configuration.hasReflection,
            opacity: configuration.opacity,
            animationType: configuration.animationType,
            animationDuration: configuration.animationDuration,
            animationStartTime: configuration.animationStartTime
        )
    }
    
    private func calculateTextSize(text: String, fontName: String, fontSize: CGFloat, maxWidth: CGFloat) -> CGSize {
        let font = UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        
        let constraintRect = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        
        // Add padding
        return CGSize(
            width: ceil(boundingBox.width) + 20,
            height: ceil(boundingBox.height) + 20
        )
    }
}
