//
//  StickerModel.swift
//  LayerDemo
//
//  Created by BCL Device 5 on 8/1/26.
//

import UIKit

struct StickerModel {
    let id: String
    var type: StickerType
    var layer: CALayer?
    var position: CGPoint
    var size: CGSize
    var rotation: CGFloat = 0
    var scale: CGFloat = 1.0
    var color: UIColor?
    var image: UIImage?
    var zIndex: Int = 0
    var isSelected: Bool = false
    
    // For lines
    var isHorizontal: Bool? = nil
    var initialEdge: Edge? = nil
    
    init(id: String = UUID().uuidString,
         type: StickerType,
         position: CGPoint,
         size: CGSize,
         color: UIColor? = nil,
         image: UIImage? = nil,
         zIndex: Int = 0,
         isHorizontal: Bool? = nil,
         initialEdge: Edge? = nil) {
        self.id = id
        self.type = type
        self.position = position
        self.size = size
        self.color = color
        self.image = image
        self.zIndex = zIndex
        self.isHorizontal = isHorizontal
        self.initialEdge = initialEdge
    }
}
