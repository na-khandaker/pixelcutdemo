//
//  ViewController.swift
//
import UIKit
import Photos
import AVFoundation
import AVKit
import MobileCoreServices

class ViewController: UIViewController {
    
    // MARK: - Properties
    private var currentSelectedAnimation: AnimationType = .RevealRight
    private var stickerManager = StickerManager()
    private var imageCounter = 0
    
    // MARK: - IBOutlets
    @IBOutlet weak var animationCollectionView: UICollectionView!
    @IBOutlet weak var canvasView: UIView!
    
    // MARK: - Constants
    private let LINE_WIDTH: CGFloat = 12.0
    private let DURATION: TimeInterval = 1.2
    private let videoSize = CGSize(width: 1080, height: 1920)
    private let fps: Int32 = 60
    
    // MARK: - State
    private var lastPanPosition: CGPoint?
    private var lastRotation: CGFloat = 0
    private var lastScale: CGFloat = 1.0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        canvasView.layer.masksToBounds = true
        //setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupGestures()
        createInitialStickers()
        animateAllStickers()
    }
    
    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        canvasView.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        canvasView.addGestureRecognizer(tap)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        canvasView.addGestureRecognizer(pinch)
        
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        canvasView.addGestureRecognizer(rotation)
        
        canvasView.isUserInteractionEnabled = true
    }
    
    // MARK: - Initial Stickers Creation
    private func createInitialStickers() {
        createEdgeLines()
        createInitialImage()
        createInitialText()
    }

    private func createInitialText() {
        let canvasBounds = canvasView.bounds
        
        // Create a text sticker with reflection
        let textConfig = TextStickerConfiguration(
            position: CGPoint(x: canvasBounds.midX, y: canvasBounds.midY - 150),
            size: CGSize(width: 300, height: 80),
            text: "Hello World!",
            fontSize: 36,
            fontName: "Helvetica-Bold",
            textColor: .blue,
            backgroundColor: .clear,
            zIndex: 20,
            hasReflection: true,
            opacity: 1.0
        )
        
        let textSticker = StickerFactory.shared.createTextSticker(configuration: textConfig)
        addStickerToCanvas(textSticker)
//        
//        // Create another text sticker with different properties
//        let textConfig2 = TextStickerConfiguration(
//            position: CGPoint(x: canvasBounds.midX, y: canvasBounds.midY + 150),
//            size: CGSize(width: 250, height: 60),
//            text: "Reflection Demo",
//            fontSize: 28,
//            fontName: "ARIAL",
//            textColor: UIColor.systemPink,
//            backgroundColor: UIColor.black.withAlphaComponent(0.3),
//            zIndex: 21,
//            hasReflection: false,
//            opacity: 0.9
//        )
//        
//        let textSticker2 = StickerFactory.shared.createTextSticker(configuration: textConfig2)
//        addStickerToCanvas(textSticker2)
    }
    
    private func createEdgeLines() {
        let canvasBounds = canvasView.bounds
        
        // Top line
        let topConfig = LineStickerConfiguration(
            position: CGPoint(x: 0, y: LINE_WIDTH / 2),
            size: CGSize(width: 1, height: LINE_WIDTH),
            color: .systemBlue,
            isHorizontal: true,
            initialEdge: .top,
            lineWidth: LINE_WIDTH,
            zIndex: 0,
            hasReflection: false,
            opacity: 1.0
        )
        let topSticker = StickerFactory.shared.createLineSticker(configuration: topConfig)
        addStickerToCanvas(topSticker)
        
        // Bottom line
        let bottomConfig = LineStickerConfiguration(
            position: CGPoint(x: canvasBounds.width, y: canvasBounds.height - LINE_WIDTH / 2),
            size: CGSize(width: 1, height: LINE_WIDTH),
            color: .systemRed,
            isHorizontal: true,
            initialEdge: .bottom,
            lineWidth: LINE_WIDTH,
            zIndex: 1,
            hasReflection: false,
            opacity: 1.0
        )
        let bottomSticker = StickerFactory.shared.createLineSticker(configuration: bottomConfig)
        addStickerToCanvas(bottomSticker)
        
        // Left line
        let leftConfig = LineStickerConfiguration(
            position: CGPoint(x: LINE_WIDTH / 2, y: 0),
            size: CGSize(width: LINE_WIDTH, height: 1),
            color: .systemGreen,
            isHorizontal: false,
            initialEdge: .left,
            lineWidth: LINE_WIDTH,
            zIndex: 2,
            hasReflection: false,
            opacity: 1.0
        )
        let leftSticker = StickerFactory.shared.createLineSticker(configuration: leftConfig)
        addStickerToCanvas(leftSticker)
        
        // Right line
        let rightConfig = LineStickerConfiguration(
            position: CGPoint(x: canvasBounds.width - LINE_WIDTH / 2, y: canvasBounds.height),
            size: CGSize(width: LINE_WIDTH, height: 1),
            color: .systemOrange,
            isHorizontal: false,
            initialEdge: .right,
            lineWidth: LINE_WIDTH,
            zIndex: 3,
            hasReflection: false,
            opacity: 1.0
        )
        let rightSticker = StickerFactory.shared.createLineSticker(configuration: rightConfig)
        addStickerToCanvas(rightSticker)
    }
    
    private func createInitialImage() {
        guard let image = UIImage(named: "testImage") else { return }
        
        let size: CGFloat = canvasView.bounds.width / 3
        let config = ImageStickerConfiguration(
            position: CGPoint(x: canvasView.bounds.width / 2, y: canvasView.bounds.height / 2),
            size: CGSize(width: size, height: size),
            image: image,
            color: .clear,
            zIndex: 10,
            hasReflection: true,
            opacity: 1.0
        )
        
        let imageSticker = StickerFactory.shared.createImageSticker(configuration: config)
        addStickerToCanvas(imageSticker)
    }
    
    // MARK: - Sticker Management
//    private func addStickerToCanvas(_ sticker: StickerModel) {
//        // Create layer
//        let layer = LayerBuilder.shared.createLayer(from: sticker)
//        canvasView.layer.addSublayer(layer)
//        
//        // Update sticker with layer reference
//        var updatedSticker = sticker
//        updatedSticker.layer = layer
//        stickerManager.addSticker(updatedSticker)
//        
//        // Select the new sticker
//        stickerManager.setSelectedSticker(withId: updatedSticker.id)
//        highlightSelectedSticker()
//    }
    private func addStickerToCanvas(_ sticker: StickerModel) {
        // Create main layer
        let layer = LayerBuilder.shared.createLayer(from: sticker)
        canvasView.layer.addSublayer(layer)
        
        // Create a mutable copy to update
        var updatedSticker = sticker
        updatedSticker.layer = layer
        
        // Add reflection if configured
        if updatedSticker.hasReflection {
            let reflectionLayer = createReflectionLayer(for: layer)
            canvasView.layer.insertSublayer(reflectionLayer, below: layer)
            updatedSticker.reflectionLayer = reflectionLayer
        }
        
        // IMPORTANT: Add the updated sticker with layer references
        stickerManager.addSticker(updatedSticker)
        
        // Select the new sticker
        stickerManager.setSelectedSticker(withId: updatedSticker.id)
        highlightSelectedSticker()
    }

    private func createReflectionLayer(for mainLayer: CALayer) -> CALayer {
        let reflectionLayer = CALayer()
        
        // Check if main layer contains a CATextLayer
        if let textLayer = mainLayer.sublayers?.first as? CATextLayer {
            // Handle text layer reflection
            let textReflectionLayer = CATextLayer()
            textReflectionLayer.string = textLayer.string
            textReflectionLayer.font = textLayer.font
            textReflectionLayer.fontSize = textLayer.fontSize
            textReflectionLayer.foregroundColor = textLayer.foregroundColor
            textReflectionLayer.alignmentMode = textLayer.alignmentMode
            textReflectionLayer.isWrapped = textLayer.isWrapped
            textReflectionLayer.contentsScale = textLayer.contentsScale
            textReflectionLayer.frame = textLayer.frame
            
            // Apply container background if exists
            reflectionLayer.backgroundColor = mainLayer.backgroundColor
            reflectionLayer.cornerRadius = mainLayer.cornerRadius
            
            reflectionLayer.addSublayer(textReflectionLayer)
            
        } else if let firstSublayer = mainLayer.sublayers?.first {
            // Handle image/shape layer reflection
            reflectionLayer.contents = firstSublayer.contents
            reflectionLayer.contentsScale = firstSublayer.contentsScale
            reflectionLayer.contentsGravity = firstSublayer.contentsGravity
            reflectionLayer.cornerRadius = firstSublayer.cornerRadius
            reflectionLayer.masksToBounds = firstSublayer.masksToBounds
            reflectionLayer.backgroundColor = firstSublayer.backgroundColor
            reflectionLayer.frame = firstSublayer.frame
        } else {
            // Fallback to main layer properties
            reflectionLayer.frame = mainLayer.bounds
            reflectionLayer.backgroundColor = mainLayer.backgroundColor
            reflectionLayer.cornerRadius = mainLayer.cornerRadius
        }
        
        // Position reflection below the main layer
        let mainPosition = mainLayer.position
        let mainHeight = mainLayer.bounds.height
        reflectionLayer.position = CGPoint(
            x: mainPosition.x,
            y: mainPosition.y + mainHeight
        )
        
        // Apply vertical flip (mirror effect)
        var reflectionTransform = mainLayer.transform
        reflectionTransform = CATransform3DScale(reflectionTransform, 1, -1, 1)
        reflectionLayer.transform = reflectionTransform
        
        // Reduced opacity for reflection effect
        reflectionLayer.opacity = 1//0.75
        
        // Mark as reflection layer (for hit testing)
        reflectionLayer.name = "reflection_layer"
        
        // Set zPosition below the main layer
        reflectionLayer.zPosition = mainLayer.zPosition - 1
        
        // Add gradient mask for fade-out effect
        let gradientMask = CAGradientLayer()
        gradientMask.frame = reflectionLayer.bounds
        gradientMask.colors = [
            UIColor.blue.withAlphaComponent(0).cgColor,
            UIColor.blue.withAlphaComponent(1).cgColor
        ]
        gradientMask.locations = [0.0, 1.0]
        gradientMask.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientMask.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        reflectionLayer.mask = gradientMask
        
        return reflectionLayer
    }

    private func updateReflectionForSticker(_ sticker: StickerModel) {
        guard let mainLayer = sticker.layer,
              let reflectionLayer = sticker.reflectionLayer else {
            return
        }
        
        // Update position to stay below main layer
        let mainPosition = mainLayer.position
        let mainHeight = mainLayer.bounds.height
        reflectionLayer.position = CGPoint(x: mainPosition.x, y: mainPosition.y + mainHeight)
        
        // Update transform to match main layer (with vertical flip)
        var reflectionTransform = mainLayer.transform
        reflectionTransform = CATransform3DScale(reflectionTransform, 1, -1, 1)
        reflectionLayer.transform = reflectionTransform
        
        // Update opacity
        reflectionLayer.opacity = mainLayer.opacity //* 0.75
        
        // Update bounds
        reflectionLayer.bounds = mainLayer.bounds
        
        // Update zPosition
        reflectionLayer.zPosition = mainLayer.zPosition - 1
        
        // Update the gradient mask frame
        if let gradientMask = reflectionLayer.mask as? CAGradientLayer {
            gradientMask.frame = reflectionLayer.bounds
        }
        
        // Special handling for text layer reflection
        if let textLayer = mainLayer.sublayers?.first as? CATextLayer,
           let textReflectionLayer = reflectionLayer.sublayers?.first as? CATextLayer {
            
            // Update text properties
            textReflectionLayer.string = textLayer.string
            textReflectionLayer.fontSize = textLayer.fontSize
            textReflectionLayer.foregroundColor = textLayer.foregroundColor
            textReflectionLayer.frame = textLayer.frame
            
            // Update background color
            reflectionLayer.backgroundColor = mainLayer.backgroundColor
        }
    }
    
    private func updateStickerLayer(_ sticker: StickerModel) {
        guard let layer = sticker.layer else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        layer.position = sticker.position
        layer.bounds.size = sticker.size
        layer.transform = CATransform3DMakeRotation(sticker.rotation, 0, 0, 1)
        layer.transform = CATransform3DScale(layer.transform, sticker.scale, sticker.scale, 1)
        layer.opacity = sticker.opacity
        
        // Handle different sticker types
        switch sticker.type {
        case .text:
            if let textSticker = sticker as? TextStickerModel,
               let textLayer = layer.sublayers?.first as? CATextLayer {
                textLayer.string = textSticker.text
                textLayer.fontSize = textSticker.fontSize
                textLayer.foregroundColor = textSticker.textColor.cgColor
                if let fontName = textSticker.fontName {
                    textLayer.font = CTFontCreateWithName(fontName as CFString, textSticker.fontSize, nil)
                }
            }
        case .image:
            if let imageSticker = sticker as? ImageStickerModel,
               let imageLayer = layer.sublayers?.first {
                imageLayer.contents = imageSticker.image.cgImage
                imageLayer.frame = CGRect(origin: .zero, size: sticker.size)
            }
        case .shape, .line:
            if let color = sticker.color {
                layer.backgroundColor = color.cgColor
            }
        }
        
        // CRITICAL: Update reflection after main layer updates
        if sticker.hasReflection {
            updateReflectionForSticker(sticker)
        }
        
        CATransaction.commit()
        

    }
    
    private func removeSelectedSticker() {
        guard let selectedSticker = stickerManager.selectedSticker,
              let layer = selectedSticker.layer else { return }
        
        layer.removeFromSuperlayer()
        stickerManager.removeSticker(withId: selectedSticker.id)
    }
    
    // MARK: - Gesture Handlers
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: canvasView)
        
        // Find tapped sticker using manager's hit testing
        if let tappedSticker = stickerManager.getStickerAtPoint(location, in: canvasView) {
            stickerManager.setSelectedSticker(withId: tappedSticker.id)
            highlightSelectedSticker()
            return
        }
        
        // If tapped on empty space, clear selection
        stickerManager.clearSelection()
        removeHighlight()
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let selectedSticker = stickerManager.selectedSticker,
              let layer = selectedSticker.layer else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let translation = gesture.translation(in: canvasView)
        
        if gesture.state == .began {
            layer.removeAllAnimations()
            if let reflectionLayer = selectedSticker.reflectionLayer {
                reflectionLayer.removeAllAnimations()
            }
            lastPanPosition = selectedSticker.position
        }
        
        if let lastPosition = lastPanPosition {
            var newPosition = CGPoint(
                x: lastPosition.x + translation.x,
                y: lastPosition.y + translation.y
            )
            
            // Apply constraints to keep sticker within canvas
            newPosition = constrainPosition(newPosition, for: selectedSticker)
            
            // Update sticker model
            var updatedSticker = selectedSticker
            updatedSticker.position = newPosition
            stickerManager.updateSticker(updatedSticker)
            
            // Update layer
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.position = newPosition
            CATransaction.commit()
            
            // Update reflection if exists
            if updatedSticker.hasReflection {
                updateReflectionForSticker(updatedSticker)
            }
            
           
        }
        
        if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            lastPanPosition = nil
        }
        
        CATransaction.commit()
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let selectedSticker = stickerManager.selectedSticker else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if gesture.state == .began {
            lastScale = selectedSticker.scale
        }
        
        let newScale = lastScale * gesture.scale
        
        // Update sticker model with scale limits
        var updatedSticker = selectedSticker
        updatedSticker.scale = max(0.1, min(newScale, 5.0))
        stickerManager.updateSticker(updatedSticker)
        
        // Update layer
        updateStickerLayer(updatedSticker)
        
        if gesture.state == .ended {
            lastScale = updatedSticker.scale
        }
        
        CATransaction.commit()
    }

    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let selectedSticker = stickerManager.selectedSticker else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if gesture.state == .began {
            lastRotation = selectedSticker.rotation
        }
        
        let newRotation = lastRotation + gesture.rotation
        
        // Update sticker model
        var updatedSticker = selectedSticker
        updatedSticker.rotation = newRotation
        stickerManager.updateSticker(updatedSticker)
        
        // Update layer
        updateStickerLayer(updatedSticker)
        
        if gesture.state == .ended {
            lastRotation = updatedSticker.rotation
        }
        
        CATransaction.commit()
    }
    
//    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
//        guard let selectedSticker = stickerManager.selectedSticker else { return }
//        
//        if gesture.state == .began {
//            lastScale = selectedSticker.scale
//        }
//        
//        let newScale = lastScale * gesture.scale
//        
//        // Update sticker model with scale limits
//        var updatedSticker = selectedSticker
//        updatedSticker.scale = max(0.1, min(newScale, 5.0))
//        stickerManager.updateSticker(updatedSticker)
//        
//        // Update layer
//        updateStickerLayer(updatedSticker)
//        
//        if gesture.state == .ended {
//            lastScale = updatedSticker.scale
//        }
//    }
    
//    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
//        guard let selectedSticker = stickerManager.selectedSticker else { return }
//        
//        if gesture.state == .began {
//            lastRotation = selectedSticker.rotation
//        }
//        
//        let newRotation = lastRotation + gesture.rotation
//        
//        // Update sticker model
//        var updatedSticker = selectedSticker
//        updatedSticker.rotation = newRotation
//        stickerManager.updateSticker(updatedSticker)
//        
//        // Update layer
//        updateStickerLayer(updatedSticker)
//        
//        if gesture.state == .ended {
//            lastRotation = updatedSticker.rotation
//        }
//    }
    
    // MARK: - Button Actions (IBActions)
    @IBAction func addImageTapped(_ sender: Any) {
        imageCounter += 1
        
        // For demo, use test image. In production, use image picker
        guard let image = UIImage(named: "testImage") else {
            showAlert(message: "Test image not found. Please add 'testImage' to your assets.")
            return
        }
        
        let size: CGFloat = canvasView.bounds.width / 4
        let randomX = CGFloat.random(in: size/2...(canvasView.bounds.width - size/2))
        let randomY = CGFloat.random(in: size/2...(canvasView.bounds.height - size/2))
        
        let config = ImageStickerConfiguration(
            position: CGPoint(x: randomX, y: randomY),
            size: CGSize(width: size, height: size),
            image: image,
            color: .clear,
            zIndex: 10 + imageCounter,
            hasReflection: false,
            opacity: 1.0
        )
        
        let imageSticker = StickerFactory.shared.createImageSticker(configuration: config)
        addStickerToCanvas(imageSticker)
    }
    
    @IBAction func addLineTapped(_ sender: Any) {
        let canvasBounds = canvasView.bounds
        let randomLength = CGFloat.random(in: 50...200)
        let randomThickness = CGFloat.random(in: 5...20)
        let randomX = CGFloat.random(in: 50...(canvasBounds.width - 50))
        let randomY = CGFloat.random(in: 50...(canvasBounds.height - 50))
        let isHorizontal = Bool.random()
        
        let size = isHorizontal ?
        CGSize(width: randomLength, height: randomThickness) :
        CGSize(width: randomThickness, height: randomLength)
        
        let randomColor = UIColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1.0
        )
        
        let config = LineStickerConfiguration(
            position: CGPoint(x: randomX, y: randomY),
            size: size,
            color: randomColor,
            isHorizontal: isHorizontal,
            initialEdge: nil,
            lineWidth: randomThickness,
            zIndex: 5,
            hasReflection: false,
            opacity: 1.0
        )
        
        let lineSticker = StickerFactory.shared.createLineSticker(configuration: config)
        addStickerToCanvas(lineSticker)
    }
    
    @IBAction func addTextTapped(_ sender: Any) {
        let size = CGSize(width: 200, height: 60)
        let randomX = CGFloat.random(in: size.width/2...(canvasView.bounds.width - size.width/2))
        let randomY = CGFloat.random(in: size.height/2...(canvasView.bounds.height - size.height/2))
        
        let config = TextStickerConfiguration(
            position: CGPoint(x: randomX, y: randomY),
            size: size,
            text: "Text \(imageCounter)",
            fontSize: 24,
            fontName: "Helvetica",
            textColor: .white,
            backgroundColor: .clear,
            zIndex: 15 + imageCounter,
            hasReflection: true,
            opacity: 1.0
        )
        
        let textSticker = StickerFactory.shared.createTextSticker(configuration: config)
        addStickerToCanvas(textSticker)
        imageCounter += 1
    }
    
    @IBAction func addShapeTapped(_ sender: Any) {
        let size = CGSize(width: 80, height: 80)
        let randomX = CGFloat.random(in: size.width/2...(canvasView.bounds.width - size.width/2))
        let randomY = CGFloat.random(in: size.height/2...(canvasView.bounds.height - size.height/2))
        
        let randomColor = UIColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1.0
        )
        
        let config = ShapeStickerConfiguration(
            position: CGPoint(x: randomX, y: randomY),
            size: size,
            color: randomColor,
            shapeType: .circle,
            cornerRadius: 40,
            zIndex: 8 + imageCounter,
            hasReflection: true,
            opacity: 0.8
        )
        
        let shapeSticker = StickerFactory.shared.createShapeSticker(configuration: config)
        addStickerToCanvas(shapeSticker)
        imageCounter += 1
    }
    
    @IBAction func deleteTapped(_ sender: Any) {
        removeSelectedSticker()
    }
    
    @IBAction func playTapped(_ sender: Any) {
        resetAndReanimate()
    }
    
    @IBAction func exportTapped(_ sender: Any) {
        exportAnimatedVideo()
    }
    
    // MARK: - Helper Methods
    private func constrainPosition(_ position: CGPoint, for sticker: StickerModel) -> CGPoint {
        guard let layer = sticker.layer else { return position }
        
        var constrainedPosition = position
        let layerBounds = layer.bounds
        let canvasBounds = canvasView.bounds
        
        // For other stickers, keep within canvas
        let minX = layerBounds.width * sticker.scale / 2
        let maxX = canvasBounds.width - (layerBounds.width * sticker.scale / 2)
        let minY = layerBounds.height * sticker.scale / 2
        let maxY = canvasBounds.height - (layerBounds.height * sticker.scale / 2)
        
        constrainedPosition.x = min(max(position.x, minX), maxX)
        constrainedPosition.y = min(max(position.y, minY), maxY)
        
        return constrainedPosition
    }
    
    private func highlightSelectedSticker() {
        removeHighlight()
        
        guard let selectedSticker = stickerManager.selectedSticker,
              let layer = selectedSticker.layer else { return }
        
        // Add selection border
        layer.borderWidth = 2
        layer.borderColor = UIColor.systemYellow.cgColor
        
        // Pulsing animation
        let pulse = CABasicAnimation(keyPath: "borderWidth")
        pulse.fromValue = 2
        pulse.toValue = 4
        pulse.duration = 0.5
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        layer.add(pulse, forKey: "pulse")
    }
    
    private func removeHighlight() {
        for sticker in stickerManager.allStickers {
            if let layer = sticker.layer {
                layer.removeAnimation(forKey: "pulse")
                layer.borderWidth = 0
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Info", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Animation Methods
//    private func animateAllStickers() {
//        // Animate edge lines
//        for sticker in stickerManager.lineStickers {
//            if let layer = sticker.layer, let edge = sticker.initialEdge {
//                animateLineGrowth(layer, edge: edge)
//            }
//        }
//        
//        // Animate all image, text, and shape stickers with current animation type
//        for sticker in stickerManager.allStickers {
//            if sticker.type != .line, let layer = sticker.layer {
//                LayerBuilder.shared.applyAnimation(to: layer, animationType: currentSelectedAnimation, duration: DURATION)
//            }
//        }
//    }
    
//    private func animateLineGrowth(_ layer: CALayer, edge: Edge) {
//        let animation = CABasicAnimation()
//        
//        switch edge {
//        case .top, .bottom:
//            animation.keyPath = "bounds.size.width"
//            animation.fromValue = 0
//            animation.toValue = canvasView.bounds.width
//        case .left, .right:
//            animation.keyPath = "bounds.size.height"
//            animation.fromValue = 0
//            animation.toValue = canvasView.bounds.height
//        }
//        
//        animation.duration = DURATION
//        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//        animation.fillMode = .forwards
//        animation.isRemovedOnCompletion = false
//        
//        layer.add(animation, forKey: "lineGrowth")
//    }
    
    // MARK: - Play/Reset
//    private func resetAndReanimate() {
//        // Save current states
//        let savedStickers = stickerManager.allStickers
//        
//        // Remove all layers and animations
//        canvasView.layer.sublayers?.forEach {
//            $0.removeAllAnimations()
//            $0.removeFromSuperlayer()
//        }
//        
//        // Clear sticker manager
//        stickerManager = StickerManager()
//        
//        // Recreate all stickers with saved positions
//        for var sticker in savedStickers {
//            sticker.layer = nil // Clear old layer reference
//            addStickerToCanvas(sticker)
//        }
//        
//        // Reapply animations
//        animateAllStickers()
//    }
    
    // MARK: - Export
    private func exportAnimatedVideo() {
        // Get the path to your blank video
        guard let blankVideoURL = Bundle.main.url(forResource: "square_blank", withExtension: "mov") else {
            showAlert(message: "Blank video not found in bundle")
            return
        }
        
        // Show loading indicator
        let alert = UIAlertController(title: "Exporting", message: "Please wait...", preferredStyle: .alert)
        present(alert, animated: true)
        
        // Create video manager and export
        let videoManager = VideoManager()
        
        videoManager.exportVideoWithLayerAnimation(
            blankVideoURL: blankVideoURL,
            canvasView: canvasView,
            stickerManager: stickerManager,
            currentAnimation: currentSelectedAnimation
        ) { [weak self] exportedURL in
            DispatchQueue.main.async {
                alert.dismiss(animated: true) {
                    guard let self = self else { return }
                    
                    if let url = exportedURL {
                        self.saveVideoToPhotos(url: url)
                    } else {
                        self.showAlert(message: "Failed to export video")
                    }
                }
            }
        }
    }
    
    private func saveVideoToPhotos(url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }) { saved, error in
                    DispatchQueue.main.async {
                        if saved {
                            self.showAlert(message: "Video saved to Photos!")
                        } else {
                            self.showAlert(message: "Failed to save video: \(error?.localizedDescription ?? "Unknown error")")
                        }
                        
                        // Clean up temporary file
                        try? FileManager.default.removeItem(at: url)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.showPhotoLibraryAccessAlert()
                }
            }
        }
    }
    
    private func showPhotoLibraryAccessAlert() {
        let alert = UIAlertController(
            title: "Photo Library Access Required",
            message: "Please enable photo library access in Settings to save videos and images.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
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
        cell.isSelected = (AnimationType.allCases[indexPath.row] == currentSelectedAnimation)
        return cell
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentSelectedAnimation = AnimationType.allCases[indexPath.row]
        resetAndReanimate()
        collectionView.reloadData()
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = AnimationType.allCases[indexPath.row].rawValue
        let font = UIFont.systemFont(ofSize: 14)
        let width = text.size(withAttributes: [.font: font]).width + 20
        return CGSize(width: width, height: 40)
    }
}

extension ViewController {
    // MARK: - Animation Methods (Updated to handle reflections)
    private func animateAllStickers() {
        // Animate edge lines
        for sticker in stickerManager.lineStickers {
            if let layer = sticker.layer, let edge = sticker.initialEdge {
                animateLineGrowth(layer, edge: edge)
                
                // Also animate reflection if it exists
                if let reflectionLayer = sticker.reflectionLayer {
                    animateLineGrowth(reflectionLayer, edge: edge)
                }
            }
        }
        
        // Animate all image, text, and shape stickers with current animation type
        for sticker in stickerManager.allStickers {
            if sticker.type != .line {
                if let layer = sticker.layer {
                    LayerBuilder.shared.applyAnimation(to: layer,
                                                       animationType: currentSelectedAnimation,
                                                       duration: DURATION)
                }
                
                // Apply same animation to reflection layer
                if let reflectionLayer = sticker.reflectionLayer {
                    LayerBuilder.shared.applyAnimation(to: reflectionLayer,
                                                       animationType: currentSelectedAnimation,
                                                       duration: DURATION)
                }
            }
        }
    }

    private func animateLineGrowth(_ layer: CALayer, edge: Edge) {
        let animation = CABasicAnimation()
        
        switch edge {
        case .top, .bottom:
            animation.keyPath = "bounds.size.width"
            animation.fromValue = 0
            animation.toValue = canvasView.bounds.width
        case .left, .right:
            animation.keyPath = "bounds.size.height"
            animation.fromValue = 0
            animation.toValue = canvasView.bounds.height
        }
        
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        layer.add(animation, forKey: "lineGrowth")
    }

    // MARK: - Reset and Reanimate (Updated)
    private func resetAndReanimate() {
        // Save current states
        let savedStickers = stickerManager.allStickers
        
        // Remove all layers and animations
        canvasView.layer.sublayers?.forEach {
            $0.removeAllAnimations()
            $0.removeFromSuperlayer()
        }
        
        // Clear sticker manager
        stickerManager = StickerManager()
        
        // Recreate all stickers with saved positions
        for var sticker in savedStickers {
            sticker.layer = nil // Clear old layer reference
            sticker.reflectionLayer = nil // Clear old reflection reference
            addStickerToCanvas(sticker)
        }
        
        // Reapply animations (including to reflection layers)
        animateAllStickers()
    }
}
