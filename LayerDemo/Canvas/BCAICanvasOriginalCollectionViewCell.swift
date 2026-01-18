//
//  BCAICanvasOriginalCollectionViewCell.swift
//  CanvasApp
//
//  Created by dey18 on 1/12/26.
//



import UIKit



class BCAICanvasOriginalCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var originalCanvasView: UIView!
    @IBOutlet weak var originalCanvasImageView: UIImageView!
    @IBOutlet weak var originalCanvasTitle: UILabel!
    @IBOutlet weak var canvasHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var canvasWidthConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        originalCanvasView.clipsToBounds = true
        originalCanvasView.layer.cornerRadius = 2.0
        originalCanvasView.layer.borderColor = dNavLableColor?.cgColor
        originalCanvasView.layer.borderWidth = 1.5
        
        
    }
    
    
    override var isSelected: Bool{
        didSet{
            if isSelected{
                selectedCell()
            }else{
                deSelected()
                
            }
        }
    }
    
    
    func selectedCell(){
        originalCanvasView.layer.borderColor = MENU_SELECT_COLOR?.cgColor
        originalCanvasImageView.image = UIImage(named: "sOrginalCanvas")
        originalCanvasTitle.textColor = MENU_SELECT_COLOR
    }
    
    func deSelected(){
        originalCanvasView.layer.borderColor = dNavLableColor?.cgColor
        originalCanvasImageView.image = UIImage(named: "dOrginalCanvas")
        originalCanvasTitle.textColor = dNavLableColor
        
    }
    
    func originalCanvasConfigure(bounds: CGRect){
        var ratio: CGFloat = 1.0
        
        if(bounds.height > bounds.width){
            ratio = bounds.height / bounds.width
            canvasHeightConstraint.constant = 25 * ratio
            canvasWidthConstraint.constant = 25
            
            
        }else if(bounds.width > bounds.height){
            ratio = bounds.width / bounds.height
            canvasWidthConstraint.constant = 25 * ratio
            canvasHeightConstraint.constant = 25
        }
    }
    
}
