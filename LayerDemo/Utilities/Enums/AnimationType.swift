//
//  AnimationType.swift
//  LayerDemo
//
//  Created by BCL Device 5 on 8/1/26.
//

import UIKit

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

enum Edge {
    case top
    case bottom
    case left
    case right
}
