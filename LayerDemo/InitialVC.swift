//
//  InitialVC.swift
//  LayerDemo
//
//  Created by BCL-Device-11 on 28/12/25.
//

import UIKit

class InitialVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

      
    }
    
    func applyTemplete(templeteInfo: TempleteModel) {
        if let image = templeteInfo.image {
            addImageLayer(imageModel: image)
        }
        if let sticker = templeteInfo.sticker {
            
        }
    }
    
    func addImageLayer(imageModel: ImageModel) {
        guard let img = UIImage(named: "testImage")?.cgImage else {
            print("Image not found!")
            return
        } // add image from url
        
        let size: CGFloat = view.bounds.width / 2 // add image size
        
        let imageLayer = CALayer()
        imageLayer.contents = img
        imageLayer.contentsGravity = .resizeAspectFill
        imageLayer.masksToBounds = true
        imageLayer.frame = CGRect(x: 0,
                                  y: 0,
                                  width: size,
                                  height: size)
        
        
    }
    
    func addStickerLayer(imageModel: ImageModel) {
        
    }
    
    func addTextLayer(imageModel: ImageModel) {
        
    }
    
    
}
