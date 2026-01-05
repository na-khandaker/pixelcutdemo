//
//  ViewController.swift
//  LayerDemo
//
//  Created by BCL Device 5 on 5/1/26.
//
import UIKit
import Photos

class ViewController: UIViewController {
    
    // MARK: - Properties
    private var currentSelectedAnimation: AnimationType = .DriftUp
    private var stickerManager = StickerManager()
    
    // MARK: - IBOutlets
    @IBOutlet weak var animationCollectionView: UICollectionView!
    @IBOutlet weak var canvasView: UIView!
//    @IBOutlet weak var selectedStickerLabel: UILabel!
    
    // MARK: - Constants
    private let WIDTH: CGFloat = 12.0
    private let DURATION: TimeInterval = 1.2
    private let videoSize = CGSize(width: 1080, height: 1920)
    private let fps: Int32 = 60
    
    // MARK: - State
    private var lastPanPosition: CGPoint?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        //setupCollectionView()
        updateSelectedStickerLabel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupGestures()
        createAllStickers()
        animateAllStickers()
        animateImage(with: currentSelectedAnimation)
    }
    
    // MARK: - Setup Methods
    private func setupCollectionView() {
        animationCollectionView.dataSource = self
        animationCollectionView.delegate = self
        animationCollectionView.register(UINib(nibName: "AnimationCollectionViewCell", bundle: nil),
                                         forCellWithReuseIdentifier: "AnimationCollectionViewCell")
    }
    
    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        canvasView.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        canvasView.addGestureRecognizer(tap)
        
        canvasView.isUserInteractionEnabled = true
    }
    
    // MARK: - Gesture Handlers
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: canvasView)
        
        // Check which sticker was tapped
        for stickerType in StickerType.allCases {
            if let layer = stickerManager.getSticker(for: stickerType)?.layer,
               layer.frame.contains(location) {
                stickerManager.setSelectedSticker(stickerType)
                updateSelectedStickerLabel()
                
                // Visual feedback
                highlightSelectedSticker()
                return
            }
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let selectedLayer = stickerManager.getSelectedLayer() else { return }
        
        let translation = gesture.translation(in: canvasView)
        
        if gesture.state == .began {
            lastPanPosition = selectedLayer.position
        }
        
        if let lastPosition = lastPanPosition {
            var newPosition = CGPoint(
                x: lastPosition.x + translation.x,
                y: lastPosition.y + translation.y
            )
            
            // Apply constraints based on sticker type
            newPosition = constrainPosition(newPosition, for: stickerManager.selectedStickerType)
            
            // Update position
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            selectedLayer.position = newPosition
            stickerManager.updatePosition(newPosition, for: stickerManager.selectedStickerType)
            CATransaction.commit()
        }
        
        if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            lastPanPosition = nil
            removeHighlight()
        }
    }
    
    // MARK: - Helper Methods
    private func constrainPosition(_ position: CGPoint, for stickerType: StickerType) -> CGPoint {
        guard let sticker = stickerManager.getSticker(for: stickerType),
              let layer = sticker.layer else {
            return position
        }
        
        var constrainedPosition = position
        let layerBounds = layer.bounds
        let canvasBounds = canvasView.bounds
        let anchorPoint = layer.anchorPoint
        
        switch stickerType {
        case .image:
            // Keep image within canvas
            let minX = layerBounds.width * anchorPoint.x
            let maxX = canvasBounds.width - (layerBounds.width * (1 - anchorPoint.x))
            let minY = layerBounds.height * anchorPoint.y
            let maxY = canvasBounds.height - (layerBounds.height * (1 - anchorPoint.y))
            
            constrainedPosition.x = min(max(position.x, minX), maxX)
            constrainedPosition.y = min(max(position.y, minY), maxY)
            
        case .topLine, .bottomLine:
            // Constrain Y position only (lines stay on edges)
            constrainedPosition.x = position.x
            constrainedPosition.y = sticker.position.y
            
        case .leadingLine, .trailingLine:
            // Constrain X position only
            constrainedPosition.x = sticker.position.x
            constrainedPosition.y = position.y
            
        }
        
        return constrainedPosition
    }
    
    private func highlightSelectedSticker() {
        guard let selectedLayer = stickerManager.getSelectedLayer() else { return }
        
        // Add a border to highlight the selected sticker
        selectedLayer.borderWidth = 2
        selectedLayer.borderColor = UIColor.systemYellow.cgColor
        
        // Pulsing animation
        let pulse = CABasicAnimation(keyPath: "borderWidth")
        pulse.fromValue = 2
        pulse.toValue = 4
        pulse.duration = 0.5
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        selectedLayer.add(pulse, forKey: "pulse")
    }
    
    private func removeHighlight() {
        for stickerType in StickerType.allCases {
            if let layer = stickerManager.getSticker(for: stickerType)?.layer {
                layer.removeAnimation(forKey: "pulse")
                layer.borderWidth = 0
            }
        }
    }
    
    private func updateSelectedStickerLabel() {
        let selectedType = stickerManager.selectedStickerType
        //selectedStickerLabel.text = "Selected: \(selectedType)"
    }
    
    // MARK: - Sticker Creation
    private func createAllStickers() {
        createTopLineSticker()
        createBottomLineSticker()
        createLeadingLineSticker()
        createTrailingLineSticker()
        createImageSticker(with: currentSelectedAnimation)
    }
    
    private func createTopLineSticker() {
        let position = CGPoint(x: 0, y: WIDTH / 2)
        let size = CGSize(width: 0, height: WIDTH)
        
        let layer = CALayer()
        layer.frame = CGRect(origin: .zero, size: size)
        layer.backgroundColor = UIColor.systemBlue.cgColor
        layer.anchorPoint = CGPoint(x: 0, y: 0.5)
        layer.position = position
        
        let sticker = StickerModel(
            type: .topLine,
            layer: layer,
            position: position,
            size: size,
            color: .systemBlue
        )
        
        stickerManager.setSticker(sticker, for: .topLine)
        canvasView.layer.addSublayer(layer)
    }
    
    private func createBottomLineSticker() {
        let position = CGPoint(x: canvasView.bounds.width, y: canvasView.bounds.height - WIDTH / 2)
        let size = CGSize(width: 0, height: WIDTH)
        
        let layer = CALayer()
        layer.frame = CGRect(origin: .zero, size: size)
        layer.backgroundColor = UIColor.systemRed.cgColor
        layer.anchorPoint = CGPoint(x: 1, y: 0.5)
        layer.position = position
        
        let sticker = StickerModel(
            type: .bottomLine,
            layer: layer,
            position: position,
            size: size,
            color: .systemRed
        )
        
        stickerManager.setSticker(sticker, for: .bottomLine)
        canvasView.layer.addSublayer(layer)
    }
    
    private func createLeadingLineSticker() {
        let position = CGPoint(x: WIDTH / 2, y: 0)
        let size = CGSize(width: WIDTH, height: 0)
        
        let layer = CALayer()
        layer.frame = CGRect(origin: .zero, size: size)
        layer.backgroundColor = UIColor.systemGreen.cgColor
        layer.anchorPoint = CGPoint(x: 0.5, y: 0)
        layer.position = position
        
        let sticker = StickerModel(
            type: .leadingLine,
            layer: layer,
            position: position,
            size: size,
            color: .systemGreen
        )
        
        stickerManager.setSticker(sticker, for: .leadingLine)
        canvasView.layer.addSublayer(layer)
    }
    
    private func createTrailingLineSticker() {
        let position = CGPoint(x: canvasView.bounds.width - WIDTH / 2, y: canvasView.bounds.height)
        let size = CGSize(width: WIDTH, height: 0)
        
        let layer = CALayer()
        layer.frame = CGRect(origin: .zero, size: size)
        layer.backgroundColor = UIColor.systemOrange.cgColor
        layer.anchorPoint = CGPoint(x: 0.5, y: 1)
        layer.position = position
        
        let sticker = StickerModel(
            type: .trailingLine,
            layer: layer,
            position: position,
            size: size,
            color: .systemOrange
        )
        
        stickerManager.setSticker(sticker, for: .trailingLine)
        canvasView.layer.addSublayer(layer)
    }
    
    private func createImageSticker(with animationType: AnimationType) {
        guard let cgImage = UIImage(named: "testImage")?.cgImage else {
            print("Image not found!")
            return
        }
        
        let size: CGFloat = canvasView.bounds.width / 2
        let layerSize = CGSize(width: size, height: size)
        
        // Determine position and anchor based on animation type
        let (position, anchorPoint) = getPositionAndAnchor(for: animationType, size: size)
        
        // Create image layer
        let imageLayer = CALayer()
        imageLayer.contents = cgImage
        imageLayer.contentsGravity = .resizeAspectFill
        imageLayer.masksToBounds = true
        imageLayer.frame = CGRect(origin: .zero, size: layerSize)
        imageLayer.anchorPoint = anchorPoint
        imageLayer.position = position
        
        // Create mask layer if needed for reveal animations
        if animationType == .RevealDown || animationType == .RevealUp || 
           animationType == .RevealLeft || animationType == .RevealRight {
            createMaskLayer(for: imageLayer, with: animationType, size: size)
        }
        
        let sticker = StickerModel(
            type: .image,
            layer: imageLayer,
            position: position,
            size: layerSize,
            image: UIImage(named: "testImage")
        )
        
        stickerManager.setSticker(sticker, for: .image)
        canvasView.layer.addSublayer(imageLayer)
    }
    
    private func getPositionAndAnchor(for animationType: AnimationType, size: CGFloat) -> (CGPoint, CGPoint) {
        switch animationType {
        case .RevealDown, .DriftUp, .DriftDown, .DriftLeft, .DriftRight:
            return (CGPoint(x: size / 2, y: 0), CGPoint(x: 0.5, y: 0))
        case .RevealUp:
            return (CGPoint(x: size / 2, y: size), CGPoint(x: 0.5, y: 1))
        case .RevealLeft:
            return (CGPoint(x: size, y: size / 2), CGPoint(x: 1, y: 0.5))
        case .RevealRight:
            return (CGPoint(x: 0, y: size / 2), CGPoint(x: 0.0, y: 0.5))
        default:
            return (CGPoint(x: size / 2, y: size / 2), CGPoint(x: 0.5, y: 0.5))
        }
    }
    
    private func createMaskLayer(for imageLayer: CALayer, with animationType: AnimationType, size: CGFloat) {
        let maskLayer = CALayer()
        maskLayer.backgroundColor = UIColor.black.cgColor
        
        var anchorPoint: CGPoint
        var position: CGPoint
        
        switch animationType {
        case .RevealDown:
            anchorPoint = CGPoint(x: 0.5, y: 0)
            position = CGPoint(x: size / 2, y: 0)
        case .RevealUp:
            anchorPoint = CGPoint(x: 0.5, y: 1)
            position = CGPoint(x: size / 2, y: size)
        case .RevealLeft:
            anchorPoint = CGPoint(x: 1, y: 0.5)
            position = CGPoint(x: size, y: size / 2)
        case .RevealRight:
            anchorPoint = CGPoint(x: 0.0, y: 0.5)
            position = CGPoint(x: 0, y: size / 2)
        default:
            return
        }
        
        maskLayer.frame = CGRect(x: 0, y: 0, width: size, height: size)
        maskLayer.anchorPoint = anchorPoint
        maskLayer.position = position
        imageLayer.mask = maskLayer
    }
    
    // MARK: - Animation Methods
    private func animateAllStickers() {
        animateLineSticker(.topLine, keyPath: "bounds.size.width", toValue: canvasView.bounds.width)
        animateLineSticker(.bottomLine, keyPath: "bounds.size.width", toValue: canvasView.bounds.width)
        animateLineSticker(.leadingLine, keyPath: "bounds.size.height", toValue: canvasView.bounds.height + WIDTH)
        animateLineSticker(.trailingLine, keyPath: "bounds.size.height", toValue: canvasView.bounds.height + WIDTH)
    }
    
    private func animateLineSticker(_ type: StickerType, keyPath: String, toValue: CGFloat) {
        guard let layer = stickerManager.getSticker(for: type)?.layer else { return }
        
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = 0
        animation.toValue = toValue
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        // Update model layer
        if keyPath == "bounds.size.width" {
            layer.bounds.size.width = toValue
        } else if keyPath == "bounds.size.height" {
            layer.bounds.size.height = toValue
        }
        
        layer.add(animation, forKey: "\(type)Animation")
    }
    
    private func animateImage(with type: AnimationType) {
        guard let imageLayer = stickerManager.getSticker(for: .image)?.layer else { return }
        
        switch type {
        case .RevealUp, .RevealDown, .RevealLeft, .RevealRight:
            animateImageReveal(with: type)
        case .DriftUp, .DriftDown, .DriftLeft, .DriftRight:
            animateImageDrift(with: type)
        case .Fade:
            animateImageFadeIn()
        case .Scale:
            animateImageScale()
        default:
            break
        }
    }
    
    private func animateImageReveal(with animationType: AnimationType) {
        guard let maskLayer = stickerManager.getSticker(for: .image)?.layer?.mask,
              let imageLayer = stickerManager.getSticker(for: .image)?.layer else { return }
        
        let keyPath: String
        let toValue: CGFloat
        
        switch animationType {
        case .RevealDown, .RevealUp:
            keyPath = "bounds.size.height"
            toValue = imageLayer.bounds.height
        case .RevealLeft, .RevealRight:
            keyPath = "bounds.size.width"
            toValue = imageLayer.bounds.width
        default:
            return
        }
        
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = 0
        animation.toValue = toValue
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        maskLayer.add(animation, forKey: animationType.rawValue)
    }
    
    private func animateImageDrift(with animationType: AnimationType) {
        guard let imageLayer = stickerManager.getSticker(for: .image)?.layer else { return }
        
        let animation = CABasicAnimation()
        var fromValue: CGFloat = 0
        
        switch animationType {
        case .DriftUp:
            animation.keyPath = "position.y"
            fromValue = imageLayer.position.y + canvasView.bounds.height
        case .DriftDown:
            animation.keyPath = "position.y"
            fromValue = imageLayer.position.y - canvasView.bounds.height
        case .DriftLeft:
            animation.keyPath = "position.x"
            fromValue = imageLayer.position.x + canvasView.bounds.width
        case .DriftRight:
            animation.keyPath = "position.x"
            fromValue = imageLayer.position.x - canvasView.bounds.width
        default:
            return
        }
        
        animation.fromValue = fromValue
        animation.toValue = animation.keyPath == "position.x" ? imageLayer.position.x : imageLayer.position.y
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        imageLayer.add(animation, forKey: animationType.rawValue)
    }
    
    private func animateImageFadeIn() {
        guard let imageLayer = stickerManager.getSticker(for: .image)?.layer else { return }
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        imageLayer.opacity = 1.0
        imageLayer.add(animation, forKey: "fadeIn")
    }
    
    private func animateImageScale() {
        guard let imageLayer = stickerManager.getSticker(for: .image)?.layer else { return }
        
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 0.5
        animation.toValue = 1.0
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        imageLayer.setAffineTransform(CGAffineTransform(scaleX: 1.0, y: 1.0))
        imageLayer.add(animation, forKey: "scale")
    }
    
    // MARK: - IBActions
    @IBAction func tappedOnPlayButton(_ sender: UIButton) {
        resetAndReanimate()
    }
    
    @IBAction func exportTapped(_ sender: UIButton) {
        exportAnimatedVideo()
    }
    
    private func resetAndReanimate() {
        // Save current positions
        var savedPositions: [StickerType: CGPoint] = [:]
        for stickerType in StickerType.allCases {
            savedPositions[stickerType] = stickerManager.getSticker(for: stickerType)?.position
        }
        
        // Remove all layers and animations
        canvasView.layer.sublayers?.forEach {
            $0.removeAllAnimations()
            $0.removeFromSuperlayer()
        }
        
        // Recreate all stickers
        createAllStickers()
        
        // Restore positions
        for (stickerType, position) in savedPositions {
            if let layer = stickerManager.getSticker(for: stickerType)?.layer {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                layer.position = position
                stickerManager.updatePosition(position, for: stickerType)
                CATransaction.commit()
            }
        }
        
        // Reanimate
        animateAllStickers()
        animateImage(with: currentSelectedAnimation)
    }
    
    private func exportAnimatedVideo() {
        // Your existing export code
        // ...
    }
}

// MARK: - UICollectionView Extensions
extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AnimationType.allCases.count
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
        resetAndReanimate()
    }
}

// MARK: - StickerType Extension
extension StickerType: CaseIterable {
    static var allCases: [StickerType] {
        return [.topLine, .bottomLine, .leadingLine, .trailingLine, .image]
    }
}
