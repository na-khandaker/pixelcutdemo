//
//  StickerManager.swift
//  LayerDemo
//
//  Created by BCL Device 5 on 8/1/26.
//

import UIKit

// MARK: - Sticker Manager
class StickerManager {
    private var stickers: [String: StickerModel] = [:]
    private(set) var selectedStickerId: String?
    
    var allStickers: [StickerModel] {
        return Array(stickers.values).sorted { $0.zIndex < $1.zIndex }
    }
    
    var selectedSticker: StickerModel? {
        guard let selectedId = selectedStickerId else { return nil }
        return stickers[selectedId]
    }
    
    var imageStickers: [StickerModel] {
        return stickers.values.filter { $0.type == .image }
    }
    
    var lineStickers: [StickerModel] {
        return stickers.values.filter { $0.type == .line }
    }
    
    func addSticker(_ sticker: StickerModel) {
        stickers[sticker.id] = sticker
        if selectedStickerId == nil {
            selectedStickerId = sticker.id
        }
    }
    
    func updateSticker(_ sticker: StickerModel) {
        stickers[sticker.id] = sticker
    }
    
    func removeSticker(withId id: String) {
        stickers.removeValue(forKey: id)
        if selectedStickerId == id {
            selectedStickerId = stickers.keys.first
        }
    }
    
    func getSticker(withId id: String) -> StickerModel? {
        return stickers[id]
    }
    
    func setSelectedSticker(withId id: String) {
        selectedStickerId = id
        
        // Update all stickers' selection state
        for (stickerId, var sticker) in stickers {
            sticker.isSelected = (stickerId == id)
            stickers[stickerId] = sticker
        }
    }
    
    func clearSelection() {
        selectedStickerId = nil
        for (stickerId, var sticker) in stickers {
            sticker.isSelected = false
            stickers[stickerId] = sticker
        }
    }
    
    // MARK: - Hit Testing
    // MARK: - Improved Hit Testing using CALayer's hitTest
    func getStickerAtPoint(_ point: CGPoint, in canvasView: UIView) -> StickerModel? {
        // Check from top to bottom (reverse z-order)
        let sortedStickers = allStickers.sorted { $0.zIndex > $1.zIndex }
        
        // Convert point to the coordinate system of each layer
        for sticker in sortedStickers {
            guard let layer = sticker.layer else { continue }
            
            // Get the presentation layer (for animated layers)
            let presentationLayer = layer.presentation() ?? layer
            
            // Convert point to layer's coordinate system
            let pointInLayer = canvasView.layer.convert(point, to: presentationLayer)
            
            // Check if point is in the layer's bounds
            var hitBounds = presentationLayer.bounds
            
            // For lines, expand the hit area
            if sticker.type == .line {
                let hitMargin: CGFloat = 30.0 // Even larger for lines
                if let isHorizontal = sticker.isHorizontal {
                    if isHorizontal {
                        // Horizontal line - expand vertically
                        hitBounds = hitBounds.insetBy(dx: 0, dy: -hitMargin)
                    } else {
                        // Vertical line - expand horizontally
                        hitBounds = hitBounds.insetBy(dx: -hitMargin, dy: 0)
                    }
                }
            }
            
            if hitBounds.contains(pointInLayer) {
                return sticker
            }
        }
        
        return nil
    }
    
    private func isPoint(_ point: CGPoint, inSticker sticker: StickerModel, canvasView: UIView) -> Bool {
        guard let layer = sticker.layer else { return false }
        
        // Convert point to layer's coordinate system
        let layerPoint = layer.convert(point, from: canvasView.layer)
        
        // Create hit test area (larger than visual bounds for easier tapping)
        let hitArea: CGRect
        
        if sticker.type == .line {
            // For lines, create a larger hit area
            let hitMargin: CGFloat = 20.0
            
            if let isHorizontal = sticker.isHorizontal, isHorizontal {
                // Horizontal line
                hitArea = CGRect(
                    x: layer.bounds.minX,
                    y: layer.bounds.midY - hitMargin,
                    width: layer.bounds.width,
                    height: hitMargin * 2
                )
            } else {
                // Vertical line
                hitArea = CGRect(
                    x: layer.bounds.midX - hitMargin,
                    y: layer.bounds.minY,
                    width: hitMargin * 2,
                    height: layer.bounds.height
                )
            }
        } else {
            // For images and shapes, use actual bounds
            hitArea = layer.bounds
        }
        
        return hitArea.contains(layerPoint)
    }
}
