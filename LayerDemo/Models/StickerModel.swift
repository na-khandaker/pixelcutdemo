//
//  StickerModel.swift
//  LayerDemo
//
//  Created by BCL Device 5 on 5/1/26.
//

import UIKit

// MARK: - Models
struct StickerModel {
    var type: StickerType
    var layer: CALayer?
    var position: CGPoint
    var size: CGSize
    var color: UIColor?
    var image: UIImage?
}

enum StickerType {
    case topLine
    case bottomLine
    case leadingLine
    case trailingLine
    case image
}

enum AnimationType: String, CaseIterable, Decodable {
    case RevealUp = "RevealUp"
    case RevealDown = "RevealDown"
    case RevealLeft = "RevealLeft"
    case RevealRight = "RevealRight"
    case DriftUp = "DriftUp"
    case DriftDown = "DriftDown"
    case DriftLeft = "DriftLeft"
    case DriftRight = "DriftRight"
    case None = "None"
    case Fade = "Fade"
    case Scale = "Scale"
}

// MARK: - Sticker Manager
class StickerManager {
    private var stickers: [StickerType: StickerModel] = [:]
    private(set) var selectedStickerType: StickerType = .image
    
    func setSticker(_ sticker: StickerModel, for type: StickerType) {
        stickers[type] = sticker
    }
    
    func getSticker(for type: StickerType) -> StickerModel? {
        return stickers[type]
    }
    
    func updatePosition(_ position: CGPoint, for type: StickerType) {
        stickers[type]?.position = position
        stickers[type]?.layer?.position = position
    }
    
    func updateLayer(_ layer: CALayer, for type: StickerType) {
        stickers[type]?.layer = layer
    }
    
    func setSelectedSticker(_ type: StickerType) {
        selectedStickerType = type
    }
    
    func getSelectedSticker() -> StickerModel? {
        return stickers[selectedStickerType]
    }
    
    func getSelectedLayer() -> CALayer? {
        return stickers[selectedStickerType]?.layer
    }
}
