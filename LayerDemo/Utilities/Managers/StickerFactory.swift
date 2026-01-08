//
//  StickerFactory.swift
//  LayerDemo
//
//  Created by BCL Device 5 on 8/1/26.
//

import UIKit

// MARK: - Protocol for Sticker Factory
protocol StickerFactoryProtocol {
    func createSticker(type: StickerType,
                       configuration: StickerConfiguration) -> StickerModel
}

struct StickerConfiguration {
    var position: CGPoint
    var size: CGSize
    var color: UIColor?
    var image: UIImage?
    var edge: Edge?
    var zIndex: Int = 0
    var isSelectable: Bool = true
}

// MARK: - Sticker Factory
class StickerFactory: StickerFactoryProtocol {
    static let shared = StickerFactory()
    
    private init() {}
    
    func createSticker(type: StickerType,
                       configuration: StickerConfiguration) -> StickerModel {
        switch type {
        case .line:
            return createLineSticker(configuration: configuration)
        case .image:
            return createImageSticker(configuration: configuration)
        case .shape:
            return createShapeSticker(configuration: configuration)
        }
    }
    
    private func createLineSticker(configuration: StickerConfiguration) -> StickerModel {
        let isHorizontal = configuration.size.height < configuration.size.width
        let initialEdge: Edge? = configuration.edge
        
        return StickerModel(
            type: .line,
            position: configuration.position,
            size: configuration.size,
            color: configuration.color ?? getColorForEdge(configuration.edge),
            zIndex: configuration.zIndex,
            isHorizontal: isHorizontal,
            initialEdge: initialEdge
        )
    }
    
    private func createImageSticker(configuration: StickerConfiguration) -> StickerModel {
        return StickerModel(
            type: .image,
            position: configuration.position,
            size: configuration.size,
            image: configuration.image,
            zIndex: configuration.zIndex
        )
    }
    
    private func createShapeSticker(configuration: StickerConfiguration) -> StickerModel {
        return StickerModel(
            type: .shape,
            position: configuration.position,
            size: configuration.size,
            color: configuration.color ?? .systemPurple,
            zIndex: configuration.zIndex
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
