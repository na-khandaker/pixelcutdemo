//
//  ViewController.swift
//  LayerDemo
//
//  Created by BCL-Device-11 on 8/12/25.
//

import UIKit
import Photos

// MARK: - Animation Types


class ViewController: UIViewController {
    
    var currentSelectedAnimation: AnimationType = .DriftUp
    
    
    @IBOutlet weak var animationCollectionView: UICollectionView!
    @IBOutlet weak var canvasView: UIView!
    
    let videoSize = CGSize(width: 1080, height: 1920)
    let fps: Int32 = 60
    
    var topLineLayer: CALayer!
    var bottomLineLayer: CALayer!
    var leadingLineLayer: CALayer!
    var trailingLineLayer: CALayer!
    var imageLayer: CALayer!
    var imageMaskLayer: CALayer!

    
    var WIDTH = 12.0
    var DURATION = 1.2
    var lastPanPosition: CGPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        canvasView.addGestureRecognizer(pan)
        canvasView.isUserInteractionEnabled = true
        
        createTopLine()
        animateTopLine()
        
        createLeadingLine()
        animateLeadingLine()
        
        createBottomLine()
        animateBottomLine()
        
        createTrailingLine()
        animateTrailingLine()
        
        createImageLayer(with: currentSelectedAnimation)
        animateImageFadeIn()
    }
    
    func animateImage(with type: AnimationType) {
        switch type {
        case .RevealUp, .RevealDown, .RevealLeft, .RevealRight:
            animateImageReveal(with: type)
            
        case .DriftUp, .DriftDown, .DriftLeft, .DriftRight:
            animateImageDrift(with: type)
            
        case .None, .Fade, .Sacel:
            break
        }
    }
    
    private func animateImageRevealDown() {
        let size = imageLayer.bounds.height
        
        let anim = CABasicAnimation(keyPath: "bounds.size.height")
        anim.fromValue = 0
        anim.toValue = size
        anim.duration = DURATION
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        
        //        // Final state update
        //        imageMaskLayer.bounds.size.height = size
        //        imageMaskLayer.frame.origin.y = imageLayer.bounds.height - size
        
        imageMaskLayer.add(anim, forKey: "revealUp")
    }
    
    private func animateImageReveal(with animationType: AnimationType) {
        
        var size = imageLayer.bounds.width
        var anim = CABasicAnimation(keyPath: "bounds.size.height")
        
        switch animationType {
        case .RevealDown, .RevealUp:
            size = imageLayer.bounds.height
            anim = CABasicAnimation(keyPath: "bounds.size.height")
        case .RevealLeft, .RevealRight:
            size = imageLayer.bounds.width
            anim = CABasicAnimation(keyPath: "bounds.size.width")
            default:
            break
        }
        
        anim.fromValue = 0
        anim.toValue = size
        anim.duration = DURATION
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        
        //        // Final state update
        //        imageMaskLayer.bounds.size.height = size
        //        imageMaskLayer.frame.origin.y = imageLayer.bounds.height - size
        
        imageMaskLayer.add(anim, forKey: animationType.rawValue)
    }

    private func createImageLayer() {
        guard let img = UIImage(named: "testImage")?.cgImage else {
            print("Image not found!")
            return
        }
        
        let size: CGFloat = canvasView.bounds.width / 2
        
        imageLayer = CALayer()
        imageLayer.contents = img
        imageLayer.contentsGravity = .resizeAspectFill
        imageLayer.masksToBounds = true
        imageLayer.frame = CGRect(x: 0,
                                  y: 0,
                                  width: size,
                                  height: size)
        imageLayer.anchorPoint = CGPoint(x: 0.5, y: 0) // top-center
        imageLayer.position = CGPoint(x:  size / 2, y: 0)
        canvasView.layer.addSublayer(imageLayer)
        
        // --- MASK LAYER FOR REVEAL UP ---
        imageMaskLayer = CALayer()
        imageMaskLayer.backgroundColor = UIColor.black.cgColor
        imageMaskLayer.frame = CGRect(x: 0,
                                      y: 0,    // start completely hidden
                                      width: size,
                                      height: size)
        imageMaskLayer.anchorPoint = CGPoint(x: 0.5, y: 0) // top-center
        imageMaskLayer.position = CGPoint(x:  size / 2, y: 0)
        imageLayer.mask = imageMaskLayer
    }
    
    private func createImageLayer(with currentAnimateionType: AnimationType) {
        guard let img = UIImage(named: "testImage")?.cgImage else {
            print("Image not found!")
            return
        }
        
        let size: CGFloat = canvasView.bounds.width / 2
        
        imageLayer = CALayer()
        imageLayer.contents = img
        imageLayer.contentsGravity = .resizeAspectFill
        imageLayer.masksToBounds = true
        imageLayer.frame = CGRect(x: 0,
                                  y: 0,
                                  width: size,
                                  height: size)
        var imageLayerAnchorPoint = CGPoint(x: 0, y: 0)
        var imageLayerPosition = CGPoint(x:  0, y: 0)
        
        switch currentAnimateionType {
        case .RevealDown, .DriftUp, .DriftDown, .DriftLeft, .DriftRight:
            imageLayerAnchorPoint = CGPoint(x: 0.5, y: 0) // top-center
            imageLayerPosition = CGPoint(x:  size / 2, y: 0)
        case .RevealUp:
            imageLayerAnchorPoint = CGPoint(x: 0.5, y: 1)
            imageLayerPosition = CGPoint(x:  size / 2, y: size)
        case .RevealLeft:
            imageLayerAnchorPoint = CGPoint(x: 1, y: 0.5)
            imageLayerPosition = CGPoint(x: size, y: size/2)
        case .RevealRight:
        
            imageLayerAnchorPoint = CGPoint(x: 0.0, y: 0.5)
            imageLayerPosition = CGPoint(x: 0, y: size/2)
        default:
        break

        }
        imageLayer.anchorPoint = imageLayerAnchorPoint
        imageLayer.position = imageLayerPosition
        canvasView.layer.addSublayer(imageLayer)
        

        // --- MASK LAYER FOR REVEAL UP ---
        if currentAnimateionType == .RevealDown || currentAnimateionType == .RevealUp || currentAnimateionType == .RevealLeft || currentAnimateionType == .RevealRight {
     
        imageMaskLayer = CALayer()
        imageMaskLayer.backgroundColor = UIColor.black.cgColor

        var maskLayerAnchorPoint = CGPoint(x: 0, y: 0)
        var maskLayerPosition = CGPoint(x:  size / 2, y: size)
        
        switch currentAnimateionType {
        case .RevealDown:
            maskLayerAnchorPoint =  CGPoint(x: 0.5, y: 0)// top-center
            maskLayerPosition =  CGPoint(x:  size / 2, y: 0)
        case .RevealUp:
            maskLayerAnchorPoint = CGPoint(x: 0.5, y: 1)
            maskLayerPosition = CGPoint(x:  size / 2, y: size)
        case .RevealLeft:
            maskLayerAnchorPoint = CGPoint(x: 1, y: 0.5)
            maskLayerPosition = CGPoint(x: size, y: size/2)
        case .RevealRight:
            maskLayerAnchorPoint = CGPoint(x: 0.0, y: 0.5)
            maskLayerPosition = CGPoint(x: 0, y: size/2)
        default:
        break

        }
        imageMaskLayer.frame = CGRect(x: 0,
                                      y: 0,    // start completely hidden
                                      width: size,
                                      height: size)
        imageMaskLayer.anchorPoint = maskLayerAnchorPoint // top-center
        imageMaskLayer.position = maskLayerPosition
        imageLayer.mask = imageMaskLayer
        }
    }
    
    private func animateImageScale() {

        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.fromValue = 0.5
        anim.toValue = 1.0
        anim.duration = DURATION
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false

        imageLayer.setAffineTransform(CGAffineTransform(scaleX: 1.0, y: 1.0))
        imageLayer.add(anim, forKey: "scale")
    }
    
    private func animateImageFadeIn() {

        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = 0.0
        anim.toValue = 1.0
        anim.duration = DURATION
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false

        imageLayer.opacity = 1.0
        imageLayer.add(anim, forKey: "fadeIn")
    }



    private func animateImageDriftDown() {
        
        let anim = CABasicAnimation(keyPath: "position.y")
        anim.fromValue = imageLayer.position.y - canvasView.bounds.height
        anim.toValue = 0
        anim.duration = DURATION
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        //        anim.autoreverses = false
        //        anim.repeatCount = .infinity
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        imageLayer.position.y = canvasView.bounds.height - canvasView.bounds.height
        imageLayer.add(anim, forKey: "driftDown")
    }
    
    private func animateImageDriftUp() {
        let startY: CGFloat = 0   // original top position
        let anim = CABasicAnimation(keyPath: "position.y")
        anim.fromValue = imageLayer.position.y + canvasView.bounds.height
        anim.toValue = startY
        anim.duration = DURATION
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        
        imageLayer.position.y = startY
        imageLayer.add(anim, forKey: "driftUp")
    }
    
    func animateImageDrift(with animateType: AnimationType) {
        var anim = CABasicAnimation(keyPath: "position.y")
        switch animateType {
        case .DriftUp:
            anim = CABasicAnimation(keyPath: "position.y")
            anim.fromValue = imageLayer.position.y + canvasView.bounds.height
            anim.toValue = 0
            imageLayer.position.y = 0
        case .DriftDown:
            anim = CABasicAnimation(keyPath: "position.y")
            anim.fromValue = imageLayer.position.y - canvasView.bounds.height
            anim.toValue = 0
            imageLayer.position.y = 0
        case .DriftLeft:
            anim = CABasicAnimation(keyPath: "position.x")
            let finalX = imageLayer.position.x
            let startX = finalX + canvasView.bounds.width   // right side er baire
            anim.fromValue = startX
            anim.toValue = finalX
        case .DriftRight:
            anim = CABasicAnimation(keyPath: "position.x")
            let finalX = imageLayer.position.x
            let startX = finalX - canvasView.bounds.width
            anim.fromValue = startX
            anim.toValue = finalX
        default:
            break
            
        }
        anim.duration = DURATION
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        imageLayer.add(anim, forKey: animateType.rawValue)
    }
    
    private func createTopLine() {
        topLineLayer = CALayer()
        topLineLayer.frame = CGRect(x: 0, y: 0, width: 0, height: WIDTH)
        topLineLayer.backgroundColor = UIColor.systemBlue.cgColor
        topLineLayer.anchorPoint = CGPoint(x: 0, y: 0.5) // left-center
        topLineLayer.position = CGPoint(x: 0, y: 0 + WIDTH / 2)
        canvasView.layer.addSublayer(topLineLayer)
    }
    
    private func createBottomLine() {
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        
        bottomLineLayer = CALayer()
        bottomLineLayer.frame = CGRect(x: 0, y: canvasView.bounds.height, width: 0, height: WIDTH)
        bottomLineLayer.backgroundColor = UIColor.systemRed.cgColor
        bottomLineLayer.anchorPoint = CGPoint(x: 1, y: 0.5) // right-center
        bottomLineLayer.position = CGPoint(x: canvasView.bounds.width, y: canvasView.bounds.height + WIDTH / 2)
        canvasView.layer.addSublayer(bottomLineLayer)
    }
    
    
    private func createLeadingLine() {
        leadingLineLayer = CALayer()
        leadingLineLayer.frame = CGRect(x: 0, y: 0, width: WIDTH, height: 0)
        leadingLineLayer.backgroundColor = UIColor.systemGreen.cgColor
        leadingLineLayer.anchorPoint = CGPoint(x: 0.5, y: 0) // top-center
        leadingLineLayer.position = CGPoint(x:  WIDTH / 2, y: 0)
        canvasView.layer.addSublayer(leadingLineLayer)
    }
    
    private func createTrailingLine() {
        let screenWidth = canvasView.bounds.width
        let screenHeight = canvasView.bounds.height
        trailingLineLayer = CALayer()
        trailingLineLayer.frame = CGRect(x: screenWidth - WIDTH, y: screenHeight , width: WIDTH, height: 0)
        trailingLineLayer.backgroundColor = UIColor.systemOrange.cgColor
        trailingLineLayer.anchorPoint = CGPoint(x: 0.5, y: 1) // bottom-center
        trailingLineLayer.position = CGPoint(x: screenWidth - WIDTH / 2, y: screenHeight + WIDTH)
        canvasView.layer.addSublayer(trailingLineLayer)
    }
    
    // MARK: - Animate Layers
    
    private func animateTopLine() {
        let screenWidth = view.bounds.width
        let anim = CABasicAnimation(keyPath: "bounds.size.width")
        anim.fromValue = 0
        anim.toValue = screenWidth
        anim.duration = DURATION
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        //        anim.autoreverses = true
        //        anim.repeatCount = .infinity
        
        topLineLayer.frame.size.width = screenWidth
        topLineLayer.add(anim, forKey: "topLineWidth")
    }
    
    private func animateBottomLine() {
        let screenWidth = view.bounds.width
        
        let anim = CABasicAnimation(keyPath: "bounds.size.width")
        anim.fromValue = 0
        anim.toValue = screenWidth
        anim.duration = DURATION
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        //        anim.autoreverses = true
        //        anim.repeatCount = .infinity
        
        // Update the model layer's bounds width
        bottomLineLayer.bounds.size.width = screenWidth
        bottomLineLayer.add(anim, forKey: "widthAnimation")
    }
    
    private func animateLeadingLine() {
        let screenHeight = canvasView.bounds.height + WIDTH
        let anim = CABasicAnimation(keyPath: "bounds.size.height")
        anim.fromValue = 0
        anim.toValue = screenHeight
        anim.duration = DURATION
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        //        anim.autoreverses = true
        //        anim.repeatCount = .infinity
        leadingLineLayer.frame.size.height = screenHeight
        leadingLineLayer.add(anim, forKey: "leadingLineHeight")
    }
    
    private func animateTrailingLine() {
        let screenHeight = canvasView.bounds.height
        let targetHeight = screenHeight + WIDTH
        
        let anim = CABasicAnimation(keyPath: "bounds.size.height")
        anim.fromValue = 0
        anim.toValue = targetHeight
        anim.duration = DURATION
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        //        anim.autoreverses = true
        //        anim.repeatCount = .infinity
        
        trailingLineLayer.bounds.size.height = targetHeight
        trailingLineLayer.add(anim, forKey: "trailingLineHeight")
    }
    
    @IBAction func tappedOnPlayButton(_ sender: UIButton) {
        playAgain()
    }
    
    @IBAction func exportTapped(_ sender: UIButton) {
        
    }
    
    func playAgain() {
        // 1. Remove old animations
        
        let savedPosition = imageLayer?.position
        canvasView.layer.sublayers?.forEach { $0.removeAllAnimations() }
        // 2. Remove all layers entirely
        canvasView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        // 3. Reset all references (good practice)
        topLineLayer = nil
        bottomLineLayer = nil
        leadingLineLayer = nil
        trailingLineLayer = nil
        imageMaskLayer = nil
        // 4. Recreate everything exactly like viewDidAppear()
        createTopLine()
        animateTopLine()
        
        createLeadingLine()
        animateLeadingLine()
        
        createBottomLine()
        animateBottomLine()
        
        createTrailingLine()
        animateTrailingLine()
        
        createImageLayer(with: currentSelectedAnimation)
        
        // 7. Position image at last location if available
        if let savedPosition = savedPosition {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            imageLayer?.position = savedPosition
            CATransaction.commit()
        }
        
        // 8. Run your reveal animation (from the saved position)
        animateImage(with: currentSelectedAnimation)
    }
    
    private func animateImageFromLastPosition() {
        guard let imageLayer = imageLayer else { return }
        
        // Option 1: Just fade in from current position (no movement)
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.fromValue = 0.0
        fadeAnimation.toValue = 1.0
        fadeAnimation.duration = 0.5
        fadeAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        
        imageLayer.opacity = 1.0
        imageLayer.add(fadeAnimation, forKey: "fadeIn")
        
        // Option 2: Scale up from center of last position
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.1
        scaleAnimation.toValue = 1.0
        scaleAnimation.duration = 0.8
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        imageLayer.add(scaleAnimation, forKey: "scaleUp")
        
        // Option 3: Bounce effect at current position
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        bounceAnimation.values = [0.1, 1.2, 0.9, 1.0]
        bounceAnimation.keyTimes = [0, 0.5, 0.75, 1.0]
        bounceAnimation.duration = 0.6
        
        imageLayer.add(bounceAnimation, forKey: "bounce")
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let imageLayer = imageLayer else { return }
        
        let translation = gesture.translation(in: canvasView)
        
        if gesture.state == .began {
            lastPanPosition = imageLayer.position
        }
        
        if let lastPosition = lastPanPosition {
            let newX = lastPosition.x + translation.x
            let newY = lastPosition.y + translation.y
            
            // Get image bounds in canvas coordinates
            let imageBounds = imageLayer.bounds
            let anchorPoint = imageLayer.anchorPoint
            let imageWidth = imageBounds.width
            let imageHeight = imageBounds.height
            
            // Canvas bounds
            let canvasBounds = canvasView.bounds
            
            // Constrain position to keep image within canvas
            var constrainedX = newX
            var constrainedY = newY
            
            // Calculate minimum and maximum allowed positions
            let minX = (imageWidth * anchorPoint.x)
            let maxX = canvasBounds.width - (imageWidth * (1 - anchorPoint.x))
            
            let minY = (imageHeight * anchorPoint.y)
            let maxY = canvasBounds.height - (imageHeight * (1 - anchorPoint.y))
            
            // Apply constraints
            constrainedX = min(max(newX, minX), maxX)
            constrainedY = min(max(newY, minY), maxY)
            
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            imageLayer.position = CGPoint(x: constrainedX, y: constrainedY)
            CATransaction.commit()
        }
        
        if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            lastPanPosition = nil
        }
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        AnimationType.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AnimationCollectionViewCell", for: indexPath) as! AnimationCollectionViewCell
        cell.nameLabel.text = AnimationType.allCases[indexPath.row].rawValue
        return cell
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentSelectedAnimation = AnimationType.allCases[indexPath.row]
        createImageLayer(with: currentSelectedAnimation)
        playAgain()
    }
}
