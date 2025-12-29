//
//  Templete.swift
//  LayerDemo
//
//  Created by BCL-Device-11 on 28/12/25.
//

import UIKit

// MARK: - Templete Types
enum TempleteName {
    case ShopNow
    case NewDrop
    case OnSale
}

enum AnimationType: String, Decodable, CaseIterable {
    
    case None = "none"
    case Fade = "fade"
    case Sacel = "scale"
    
    case RevealUp = "revealUp"
    case RevealDown = "revealDown"
    case RevealLeft = "revealLeft"
    case RevealRight = "revealRight"
    
    case DriftDown = "driftDown"
    case DriftUp = "driftUp"
    case DriftLeft = "driftLeft"
    case DriftRight = "driftRight"
    
}


protocol BaseProperty: Decodable {
    var animation: AnimationType { get set }
    var posX: Double { get set }
    var posY: Double { get set }
    var canMove: Bool { get set }
    var width: Double { get set }
    var hight: Double { get set }
}

struct ImageModel: Decodable, BaseProperty {
    
    var animation: AnimationType
    
    var posX: Double
    
    var posY: Double
    
    var canMove: Bool
    
    var width: Double
    
    var hight: Double
    
    var imageURL: URL?
    
}

struct TextModel: Decodable , BaseProperty {
    
    var animation: AnimationType
    
    var posX: Double
    
    var posY: Double
    
    var canMove: Bool
    
    var width: Double
    
    var hight: Double
    
    
    var text: String
    var fontName: String
    var fomtSize: Int
    var colorHex: String
}

struct TempleteModel: Decodable {
    var image:ImageModel?
    var text:TextModel?
    //    var frame:ImageModel?
    //    var highlight:[ImageModel?]
    var canvasBG:ImageModel?
}
