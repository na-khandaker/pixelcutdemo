//
//  CanvasConfig.swift
//  LayerDemo
//
//  Created by BCL Device 5 on 21/1/26.
//

import UIKit

// MARK: - JSON Decoding Models
struct CanvasConfig: Codable {
    let aspectRatio: Double?
    let backgroundColor: String?
}

struct StickerConfig: Codable {
    let id: String
    let type: String
    let relativePosition: PositionConfig
    let size: SizeConfig
    let color: String?
    let isHorizontal: Bool?
    let initialEdge: String?
    let lineWidth: CGFloat?
    let zIndex: Int
    let hasReflection: Bool
    let opacity: Float
    let animation: String?
    let animationDuration: TimeInterval?
    let rotation: CGFloat?
    let scale: CGFloat?
    
    // Text specific
    let text: String?
    let fontSize: CGFloat?
    let fontName: String?
    let textColor: String?
    let backgroundColor: String?
    let textAlignment: String?
    
    // Image specific
    let imageName: String?
    
    // Shape specific
    let shapeType: String?
    let cornerRadius: CGFloat?
}

struct PositionConfig: Codable {
    let x: CGFloat
    let y: CGFloat
}

struct SizeConfig: Codable {
    let width: CGFloat
    let height: CGFloat
}

struct AnimationSettings: Codable {
    let defaultAnimation: String?
    let defaultDuration: TimeInterval?
    let fps: Int32?
    let videoSize: VideoSizeConfig?
}

struct VideoSizeConfig: Codable {
    let width: CGFloat
    let height: CGFloat
}

struct StickerJSONConfig: Codable {
    let canvas: CanvasConfig?
    let stickers: [StickerConfig]
    let animationSettings: AnimationSettings?
}
