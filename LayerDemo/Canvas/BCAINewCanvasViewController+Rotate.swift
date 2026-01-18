//
//  BCAINewCanvasViewController+Rotate.swift
//  BCEffectsLeap
//
//  Created by BCL-Device-12 on 4/10/23.
//

import Foundation
import UIKit

extension BCAINewCanvasViewController: UIGestureRecognizerDelegate {
    
//    func addAllGesture(){
//        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//        panGesture.delegate = self
//        gestureView.addGestureRecognizer(panGesture)
//        //
//        //        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
//        //        pinchGesture.delegate = self
//        //        gestureView.addGestureRecognizer(pinchGesture)
//        
//        gestureView.isUserInteractionEnabled = true
//    }
    
    
    //    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
    //        if gesture.state == .changed {
    //
    //            let newScale = canvasStateModel.filterTransfromScale * gesture.scale
    //
    //            let minScale: CGFloat = 1.0
    //            let maxScale = 6.0
    //
    //            if newScale > maxScale{
    //                return
    //            }
    //
    //            if newScale >= minScale {
    //                imageView.transform = CGAffineTransform(scaleX: newScale, y: newScale)
    //                canvasStateModel.filterTransfromScale = newScale
    //            }
    //            gesture.scale = 1.0
    //        }
    //    }
    
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
//    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
//        
//        alignViewColor(c: .clear)
//        if isHepticOn{
//            //            hepticFeedBack()
//            isHepticOn = false
//        }
//        
//        let translation = gesture.translation(in: gestureView)
//        
//        imageView.center.x += translation.x
//        imageView.center.y += translation.y
//        setImageViewBoundaries() ///set image move boundaries
//        
//        gesture.setTranslation(.zero, in: gestureView)
//        
//        self.alignViewsSetup()
//        self.detectCanvasBGViewInset() ///show border when grayImageView touch Canvas any edges.
//        
//        if gesture.state == .ended{
//            alignViewHideShow(vFlag: true, hFlag: true)
//            canvasBgView.layer.borderWidth = 0.0
//            isHepticOn = true
//        }
//    }
    
    
    private func setImageViewBoundaries(){
        let threshold = 1.0
        
        let transformedBounds = imageView.bounds
        let transformedFrame = imageView.convert(transformedBounds, to: imageView.superview)
        
        ///bottom
        let canvasY = transformedFrame.height - canvasBgView.bounds.height
        let newY = canvasY + transformedFrame.origin.y
        
        if newY < threshold {
            imageView.frame.origin.y = -1.0*abs(canvasY)
        }
        
        ///trailing
        let canvasX = transformedFrame.width - canvasBgView.bounds.width
        let newX = canvasX + transformedFrame.origin.x
        
        if newX < threshold {
            imageView.frame.origin.x = -1.0*abs(canvasX)
        }
        
        ///top
        if transformedFrame.origin.y > 0{
            imageView.frame.origin.y = 0
        }
        
        ///leading
        if transformedFrame.origin.x > 0{
            imageView.frame.origin.x = 0
        }
        
    }
    
    
    private func alignViewsSetup(){
        let threshold = 3.0
        
        let bgY = canvasBgView.bounds.height / 2
        let bgX = canvasBgView.bounds.width / 2
        let imgC = imageView.center
        
        if abs(bgX - imgC.x) <= threshold {
            imageView.center.x = bgX
            alignViewHideShow(vFlag: false, hFlag: nil)
            isHepticOn = true
        } else {
            alignViewHideShow(vFlag: true, hFlag: nil)
        }
        
        
        if abs(bgY - imgC.y) <= threshold {
            imageView.center.y = bgY
            alignViewHideShow(vFlag: nil, hFlag: false)
            isHepticOn = true
        } else {
            alignViewHideShow(vFlag: nil, hFlag: true)
        }
        
        
        if abs(bgX - imgC.x) <= threshold && abs(bgY - imgC.y) <= threshold {
            imageView.center = CGPoint(x: bgX, y: bgY)
            alignViewHideShow(vFlag: false, hFlag: false)
            alignViewColor(c: .yellow)
            isHepticOn = true
        }
    }
    
    
    private func detectCanvasBGViewInset() {
        let threshold = 1.0
        let cTrainling = canvasBgView.bounds.width - 1
        let cBottom = canvasBgView.bounds.height - 1
        
        let gFrame = imageView.frame
        let top = gFrame.minY
        let leading = gFrame.minX
        let trailing = gFrame.maxX
        let bottom = gFrame.maxY
        
        if top < threshold || leading < threshold || trailing > cTrainling || bottom > cBottom{
            canvasBgView.layer.borderWidth = 1.0
            canvasBgView.layer.borderColor = UIColor.yellow.cgColor
            isHepticOn = true
            
        } else {
            canvasBgView.layer.borderWidth = 0.0
        }
    }
    
    
    private func alignViewHideShow(vFlag: Bool? , hFlag: Bool?){
        
        if let vFlag = vFlag{
            vView.isHidden = vFlag
        }
        
        if let hFlag = hFlag{
            hView.isHidden = hFlag
        }
    }
    
    
    private func alignViewColor(c: UIColor){
        hView.backgroundColor = c
        vView.backgroundColor = c
    }
    
    
    
}
