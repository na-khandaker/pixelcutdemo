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
    
    var textStickers: [TextStickerModel] {
        return stickers.values.compactMap { $0 as? TextStickerModel }
    }
    
    var imageStickers: [ImageStickerModel] {
        return stickers.values.compactMap { $0 as? ImageStickerModel }
    }
    
    var lineStickers: [LineStickerModel] {
        return stickers.values.compactMap { $0 as? LineStickerModel }
    }
    
    var shapeStickers: [ShapeStickerModel] {
        return stickers.values.compactMap { $0 as? ShapeStickerModel }
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
    
    func getSticker<T: StickerModel>(withId id: String) -> T? {
        return stickers[id] as? T
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
    
    // MARK: - Text Sticker Specific Methods
    func updateTextSticker(withId id: String, newText: String) {
        guard var sticker = stickers[id] as? TextStickerModel else { return }
        sticker.text = newText
        stickers[id] = sticker
        
        // Update layer if exists
        if let textLayer = sticker.layer?.sublayers?.first as? CATextLayer {
            textLayer.string = newText
        }
    }
    
    func updateTextStickerFont(withId id: String, fontSize: CGFloat, fontName: String? = nil) {
        guard var sticker = stickers[id] as? TextStickerModel else { return }
        sticker.fontSize = fontSize
        if let fontName = fontName {
            sticker.fontName = fontName
        }
        stickers[id] = sticker
        
        // Update layer if exists
        if let textLayer = sticker.layer?.sublayers?.first as? CATextLayer {
            textLayer.fontSize = fontSize
            if let fontName = fontName {
                textLayer.font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
            }
        }
    }
    
    func updateTextStickerColor(withId id: String, textColor: UIColor) {
        guard var sticker = stickers[id] as? TextStickerModel else { return }
        sticker.textColor = textColor
        stickers[id] = sticker
        
        // Update layer if exists
        if let textLayer = sticker.layer?.sublayers?.first as? CATextLayer {
            textLayer.foregroundColor = textColor.cgColor
        }
    }
    
    func toggleReflection(forStickerId id: String) {
        guard var sticker = stickers[id] else { return }
        sticker.hasReflection = !sticker.hasReflection
        stickers[id] = sticker
        
        // Update layer - would need to recreate layer with new reflection setting
        // This should be handled by the view controller
    }
    
    func updateOpacity(forStickerId id: String, opacity: Float) {
        guard var sticker = stickers[id] else { return }
        sticker.opacity = opacity
        stickers[id] = sticker
        
        // Update layer if exists
        sticker.layer?.opacity = opacity
        sticker.reflectionLayer?.opacity = opacity * 0.3
    }
}
