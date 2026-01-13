//
//  BCAICanvasCollectionViewCell.swift
//  CanvasApp
//
//  Created by dey18 on 1/12/26.
//


import UIKit


class BCAICanvasCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var canvasImgView: UIImageView!
    
    var thumbImage:UIImage?
    var selectedThumbImage:UIImage?
    
    override var isSelected: Bool{
        didSet{
            if isSelected{
                canvasImgView.image = selectedThumbImage
            }
            else{
                canvasImgView.image = thumbImage
            }
        }
    }
}
