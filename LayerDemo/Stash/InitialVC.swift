//
//  InitialVC.swift
//  LayerDemo
//
//  Created by BCL-Device-11 on 28/12/25.
//

import UIKit

//class InitialVC: UIViewController {
//    
//    var imageModelInfo = ImageModel(animation: .RevealUp, posX: 0, posY: 100, canMove: false, width: 200, hight: 200)
//    var textModel = TextModel(animation: .DriftDown, posX: 0, posY: 0, canMove: false, width: 200, hight: 100, text: "Txt", fontName: "", fomtSize: 12, colorHex: "")
//    
//    var templete = TempleteModel()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        templete = TempleteModel(image: imageModelInfo, text: textModel, canvasBG: imageModelInfo)
//        applyTemplete(templeteInfo: templete)
//    }
//    
//    func applyTemplete(templeteInfo: TempleteModel) {
//        if let image = templeteInfo.image {
//            addImageLayer(imageModel: image)
//        }
//    }
//    
//    func addImageLayer(imageModel: ImageModel) {
//        guard let img = UIImage(named: "testImage")?.cgImage else {
//            print("Image not found!")
//            return
//        }
//
//        let width = imageModel.width
//        let height = imageModel.hight
//
//        let imageLayer = CALayer()
//        imageLayer.contents = img
//        imageLayer.contentsGravity = .resizeAspectFill
//        imageLayer.masksToBounds = true
//
//        // ✅ bounds instead of frame
//        imageLayer.bounds = CGRect(x: 0, y: 0, width: width, height: height)
//
//        var anchor = CGPoint(x: 0.5, y: 0.5)
//        var position = CGPoint(x: imageModel.posX + width / 2,
//                                y: imageModel.posY + height / 2)
//
//        switch imageModel.animation {
//
//        case .RevealUp:
//            anchor = CGPoint(x: 0.5, y: 1)
//            position = CGPoint(x: imageModel.posX + width / 2,
//                                y: imageModel.posY + height)
//
//        case .RevealDown:
//            anchor = CGPoint(x: 0.5, y: 0)
//            position = CGPoint(x: imageModel.posX + width / 2,
//                                y: imageModel.posY)
//
//        case .RevealLeft:
//            anchor = CGPoint(x: 1, y: 0.5)
//            position = CGPoint(x: imageModel.posX + width,
//                                y: imageModel.posY + height / 2)
//
//        case .RevealRight:
//            anchor = CGPoint(x: 0, y: 0.5)
//            position = CGPoint(x: imageModel.posX,
//                                y: imageModel.posY + height / 2)
//
//        default:
//            break
//        }
//
//        imageLayer.anchorPoint = anchor
//        imageLayer.position = position
//
//        view.layer.addSublayer(imageLayer)
//    }
//
//    
//    func addStickerLayer(imageModel: ImageModel) {
//        
//    }
//    
//    func addTextLayer(imageModel: ImageModel) {
//        
//    }
//    
//    
//}
