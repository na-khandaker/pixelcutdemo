//
//  BCAINewCanvasViewController.swift
//  BCEffectsLeap
//
//  Created by BCL-Device-12 on 4/10/23.
//

import UIKit
import AVKit

let dNavLableColor = UIColor(named: "dNavLableColor")
let MENU_SELECT_COLOR = UIColor(named: "menuSelectColor")
let canvasDataSourcePlistName: String = "BCAICanvasDataSource"
var isHepticOn = true

func sliderHepticFeedBack() {
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    generator.prepare()
    generator.impactOccurred()
}

struct BCAICanvasInfoModel: Codable {
    let ratioW: CGFloat
    let ratioH: CGFloat
    let active: String
    let inActive: String
}

protocol BCAINewCanvasViewControllerDelegate: AnyObject {
    func didDismissNewCanvasVC(canvasModel: BCAICanvasStateModel)
}

class BCAINewCanvasViewController: UIViewController {
    
    // MARK: - Properties
    private var currentSelectedAnimation: AnimationType = .RevealRight
    var stickerManager: StickerManager!
    private var imageCounter = 0
    
    // MARK: - IBOutlets
    @IBOutlet weak var animationCollectionView: UICollectionView!
    @IBOutlet weak var canvasCollectionView: UICollectionView!
    @IBOutlet weak var gestureView: UIView!
    @IBOutlet weak var flipButtonStackView: UIStackView!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var vView: UIView!
    @IBOutlet weak var hView: UIView!
    
    // MARK: - Constants
    private let LINE_WIDTH: CGFloat = 12.0
    private let DURATION: TimeInterval = 1.2
    private let videoSize = CGSize(width: 1080, height: 1920)
    private let fps: Int32 = 60
    
    // MARK: - State
    private var lastPanPosition: CGPoint?
    private var lastRotation: CGFloat = 0
    private var lastScale: CGFloat = 1.0
    
    // MARK: - Initializer
    var selectImage = UIImage()
    var imageView = UIImageView()
    var canvasBgView = UIView()
    private var canvasDatasource: [BCAICanvasInfoModel] = []
    weak var delegate: BCAINewCanvasViewControllerDelegate?
    var bounds: CGRect = .zero
    var initialFrame: CGRect = .zero
    var canvasStateModel = BCAICanvasStateModel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if stickerManager == nil {
            stickerManager = StickerManager()
        }
        
        if let image = UIImage(named: "sampleImage") {
            selectImage = image
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.imageViewSetup()
        self.getCanvasDatasource()
        self.canvasCollectionViewSetup()
        self.setupGestures()
        
        canvasCollectionView.selectItem(at: IndexPath(row: canvasStateModel.lastSelectedIndex, section: 0),
                                        animated: true,
                                        scrollPosition: .centeredHorizontally)
        // Only create initial stickers if the sticker manager is empty
        if stickerManager.allStickers.isEmpty {
            createInitialStickers()
        } else {
            // If stickers already exist, add them to the canvas
            addExistingStickersToCanvas()
        }
        animateAllStickers()
    }
    
    private func addExistingStickersToCanvas() {
        // Remove any existing layers
        //            canvasBgView.layer.sublayers?.forEach {
        //                $0.removeFromSuperlayer()
        //            }
        let layers = canvasBgView.layer.sublayers
        
        // Add all existing stickers to the canvas
        for var sticker in stickerManager.allStickers {
            sticker.layer = nil // Clear old layer reference
            sticker.reflectionLayer = nil // Clear old reflection reference
            addStickerToCanvas(sticker)
        }
        
        // Restore selection if any
        if let selectedSticker = stickerManager.selectedSticker {
            stickerManager.setSelectedSticker(withId: selectedSticker.id)
            highlightSelectedSticker()
        }
    }
    
    // MARK: - Canvas Setup
    private func imageViewSetup() {
        imageView.transform = CGAffineTransform.identity
        
        bounds = AVMakeRect(aspectRatio: selectImage.size,
                            insideRect: gestureView.bounds)
        
        bounds = CGRectMake((gestureView.bounds.width - bounds.size.width) / 2.0,
                            (gestureView.bounds.height - bounds.size.height) / 2.0,
                            bounds.size.width,
                            bounds.size.height)
        
        canvasBgView.frame = bounds
        initialFrame = canvasBgView.frame
        canvasBgView.clipsToBounds = true
        canvasBgView.isUserInteractionEnabled = true
        
        imageView.backgroundColor = .white
        imageView.contentMode = .scaleAspectFit
        
        imageView.frame = CGRect(origin: .zero,
                                 size: CGSize(width: canvasBgView.bounds.width,
                                              height: canvasBgView.bounds.height))
        
        if let ratioW = canvasStateModel.currentRatioW, let ratioH = canvasStateModel.currentRatioH {
            if canvasStateModel.isDiffrent {
                canvasFrameChangedWithX(ratioW: ratioW, ratioH: ratioH)
            } else {
                canvasFrameChangedWithY(ratioW: ratioW, ratioH: ratioH)
            }
            changeImageCanvas()
        }
        
        imageView.transform = CGAffineTransform(scaleX: canvasStateModel.filterTransfromScale, y: canvasStateModel.filterTransfromScale)
        
        if let filterShift = canvasStateModel.filterShift {
            let absShift: CGPoint = CGPoint(x: filterShift.x * canvasBgView.frame.width,
                                            y: filterShift.y * canvasBgView.frame.height)
            imageView.frame.origin = absShift
        }
        
        self.gestureView.addSubview(self.canvasBgView)
        self.canvasBgView.addSubview(self.imageView)
        gestureView.layoutIfNeeded()
    }
    
    private func getCanvasDatasource() {
        do {
            canvasDatasource = try BACAIPlistManager.shared.loadStructFromPlist(fileName: canvasDataSourcePlistName)
        } catch {
            fatalError("Not found plist")
        }
    }
    
    private func canvasCollectionViewSetup() {
        canvasCollectionView.delegate = self
        canvasCollectionView.dataSource = self
    }
    
    private func changeImageCanvas() {
        imageView.transform = CGAffineTransform.identity
        //imageView.backgroundColor = UIColor.red
        canvasBgView.layoutIfNeeded()
        
        let bounds = CGRect(origin: .zero,
                            size: AVMakeRect(aspectRatio: selectImage.size,
                                             insideRect: canvasBgView.bounds).size)
        
        var containerFrame = CGRectMake((self.canvasBgView.frame.size.width - bounds.size.width) / 2,
                                        (self.canvasBgView.frame.size.height - bounds.size.height) / 2,
                                        bounds.size.width,
                                        bounds.size.height)
        
        var different: CGFloat = 1.0
        
        if Int(canvasBgView.bounds.height) > Int(bounds.height) {
            different = canvasBgView.bounds.height / bounds.height
        } else {
            different = canvasBgView.bounds.width / bounds.width
        }
        
        containerFrame = CGRectMake(0, 0,
                                    bounds.size.width * different,
                                    bounds.size.height * different)
        
        canvasBgView.layoutIfNeeded()
        imageView.frame = containerFrame
        imageView.center = CGPoint(x: canvasBgView.bounds.width / 2,
                                   y: canvasBgView.bounds.height / 2)
        imageView.layoutIfNeeded()
        
        // Update all sticker positions when canvas changes
        updateAllStickersForCanvasSizeChange()
    }
    
    private func canvasFrameChangedWithX(ratioW: CGFloat, ratioH: CGFloat) {
        canvasStateModel.currentRatioH = ratioH
        canvasStateModel.currentRatioW = ratioW
        canvasStateModel.isDiffrent = true
        canvasStateModel.isOrginal = false
        
        let bH = gestureView.bounds.size.height
        let bW = gestureView.bounds.size.width
        
        let width = (bH / ratioH) * ratioW
        let xOffset = (bW - width) / 2
        self.canvasBgView.frame = CGRect(x: xOffset,
                                         y: 0,
                                         width: width,
                                         height: bH)
    }
    
    private func canvasFrameChangedWithY(ratioW: CGFloat, ratioH: CGFloat) {
        canvasStateModel.currentRatioH = ratioH
        canvasStateModel.currentRatioW = ratioW
        canvasStateModel.isDiffrent = false
        canvasStateModel.isOrginal = false
        
        let bH = gestureView.bounds.size.height
        let bW = gestureView.bounds.size.width
        
        let height = (bW / ratioW) * ratioH
        let yOffset = (bH - height) / 2
        self.canvasBgView.frame = CGRect(x: 0,
                                         y: yOffset,
                                         width: bW,
                                         height: height)
    }
    
    // MARK: - Button Actions
    @IBAction func disAppearCanvasVC(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    //    @IBAction func didTapCanvasDone(_ sender: UIButton) {
    //        let childOrigin = imageView.frame.origin
    //        let shift = CGPoint(x: childOrigin.x / canvasBgView.frame.width,
    //                            y: childOrigin.y / canvasBgView.frame.height)
    //
    //        canvasStateModel.filterShift = shift
    //        delegate?.didDismissNewCanvasVC(canvasModel: canvasStateModel)
    //        dismiss(animated: true)
    //    }
    
    @IBAction func didTapCanvasDone(_ sender: UIButton) {
        let childOrigin = imageView.frame.origin
        let shift = CGPoint(x: childOrigin.x / canvasBgView.frame.width,
                            y: childOrigin.y / canvasBgView.frame.height)
        
        canvasStateModel.filterShift = shift
        delegate?.didDismissNewCanvasVC(canvasModel: canvasStateModel)
        
        // Pass back the updated sticker manager
        if self.delegate is ViewController {
            // This requires casting or modifying the delegate protocol
        }
        
        clearCanvas()
        dismiss(animated: true)
    }
    
    private func clearCanvas() {
        stickerManager.allStickers.forEach {
            $0.layer?.removeAllAnimations()
            $0.layer?.removeFromSuperlayer()
        }
    }
    
    
    // MARK: - Sticker Creation Methods
    private func createInitialStickers() {
        createEdgeLines()
        createInitialImage()
        createInitialText()
    }
    
    private func createInitialText() {
        let canvasBounds = canvasBgView.bounds
        
        // Create a text sticker with reflection
        let textConfig = TextStickerConfiguration(
            relativePosition: CGPoint(x: 0.5, y: (canvasBounds.midY - 150) / canvasBounds.height),
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
    }
    
    private func createEdgeLines() {
        let canvasBounds = canvasBgView.bounds
        
        // Top line
        let topConfig = LineStickerConfiguration(
            relativePosition: CGPoint(x: 0, y: (LINE_WIDTH / 2) / canvasBounds.height),
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
            relativePosition: CGPoint(x: 1, y: (canvasBounds.height - LINE_WIDTH / 2) / canvasBounds.height),
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
            relativePosition: CGPoint(x: (LINE_WIDTH / 2) / canvasBounds.width, y: 0),
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
            relativePosition: CGPoint(x: (canvasBounds.width - LINE_WIDTH / 2) / canvasBounds.width, y: 1),
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
        
        let size: CGFloat = canvasBgView.bounds.width / 3
        let config = ImageStickerConfiguration(
            relativePosition: CGPoint(x: 0.5, y: 0.5),
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
    
    private func addStickerToCanvas(_ sticker: StickerModel) {
        // Create main layer
        let layer = LayerBuilder.shared.createLayer(from: sticker, canvasSize: canvasBgView.bounds.size)
        canvasBgView.layer.addSublayer(layer)
        
        // Create a mutable copy to update
        var updatedSticker = sticker
        updatedSticker.layer = layer
        
        // Add reflection if configured
        if updatedSticker.hasReflection {
            let reflectionLayer = createReflectionLayer(for: layer)
            canvasBgView.layer.insertSublayer(reflectionLayer, below: layer)
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
        reflectionLayer.opacity = 0.75
        
        // Mark as reflection layer (for hit testing)
        reflectionLayer.name = "reflection_layer"
        
        // Set zPosition below the main layer
        reflectionLayer.zPosition = mainLayer.zPosition - 1
        
        // Add gradient mask for fade-out effect
        let gradientMask = CAGradientLayer()
        gradientMask.frame = reflectionLayer.bounds
        gradientMask.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(1).cgColor
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
        reflectionLayer.opacity = mainLayer.opacity * 0.75
        
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
        
        layer.position = sticker.relativePosition.absolutePosition(for: canvasBgView.bounds.size)
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
    
    // MARK: - Gesture Setup
    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        canvasBgView.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        canvasBgView.addGestureRecognizer(tap)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        canvasBgView.addGestureRecognizer(pinch)
        
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        canvasBgView.addGestureRecognizer(rotation)
        
        // Enable simultaneous gesture recognition
        //        pan.delegate = self
        //        pinch.delegate = self
        //        rotation.delegate = self
        //        tap.delegate = self
    }
    
    // MARK: - Gesture Handlers
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let selectedSticker = stickerManager.selectedSticker,
              let layer = selectedSticker.layer else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let translation = gesture.translation(in: canvasBgView)
        
        if gesture.state == .began {
            layer.removeAllAnimations()
            if let reflectionLayer = selectedSticker.reflectionLayer {
                reflectionLayer.removeAllAnimations()
            }
            lastPanPosition = layer.position // Use the layer's actual position
        }
        
        if let lastPosition = lastPanPosition {
            var newPosition = CGPoint(
                x: lastPosition.x + translation.x,
                y: lastPosition.y + translation.y
            )
            
            // Apply constraints to keep sticker within canvas
            newPosition = constrainPosition(newPosition, for: selectedSticker)
            
            // Update layer position directly
            layer.position = newPosition
            
            // Convert to relative position for storage
            let newRelativePosition = newPosition.relativePosition(for: canvasBgView.bounds.size)
            
            // Update sticker model with the new relative position
            var updatedSticker = selectedSticker
            updatedSticker.relativePosition = newRelativePosition
            stickerManager.updateSticker(updatedSticker)
            
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
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: canvasBgView)
        
        // Find tapped sticker using manager's hit testing
        if let tappedSticker = stickerManager.getStickerAtPoint(location, in: canvasBgView) {
            stickerManager.setSelectedSticker(withId: tappedSticker.id)
            highlightSelectedSticker()
            return
        }
        
        // If tapped on empty space, clear selection
        stickerManager.clearSelection()
        removeHighlight()
    }
    
    private func constrainPosition(_ position: CGPoint, for sticker: StickerModel) -> CGPoint {
        guard let layer = sticker.layer else { return position }
        
        var constrainedPosition = position
        let layerBounds = layer.bounds
        let canvasBounds = canvasBgView.bounds
        
        // For all stickers, keep within canvas using layer bounds and scale
        let minX = layerBounds.width * sticker.scale / 2
        let maxX = canvasBounds.width - (layerBounds.width * sticker.scale / 2)
        let minY = layerBounds.height * sticker.scale / 2
        let maxY = canvasBounds.height - (layerBounds.height * sticker.scale / 2)
        
        constrainedPosition.x = min(max(position.x, minX), maxX)
        constrainedPosition.y = min(max(position.y, minY), maxY)
        
        return constrainedPosition
    }
    
    // MARK: - Selection Highlighting
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
    
    // MARK: - Animation Methods
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
            animation.toValue = canvasBgView.bounds.width
        case .left, .right:
            animation.keyPath = "bounds.size.height"
            animation.fromValue = 0
            animation.toValue = canvasBgView.bounds.height
        }
        
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        layer.add(animation, forKey: "lineGrowth")
    }
    
    private func resetAndReanimate() {
        // Save current states
        let savedStickers = stickerManager.allStickers
        
        // Remove all layers and animations
        canvasBgView.layer.sublayers?.forEach {
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
    
    // MARK: - Canvas Size Change Handling
    func updateAllStickersForCanvasSizeChange() {
        guard !stickerManager.allStickers.isEmpty else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // Remove all current layers and animations
        stickerManager.allStickers.forEach {
            $0.layer?.removeAllAnimations()
            $0.layer?.removeFromSuperlayer()
            $0.reflectionLayer?.removeAllAnimations()
            $0.reflectionLayer?.removeFromSuperlayer()
        }
        
        // Get current canvas size
        let canvasSize = canvasBgView.bounds.size
        
        // Recreate all stickers at their relative positions
        for var sticker in stickerManager.allStickers {
            // Clear old layer references
            sticker.layer = nil
            sticker.reflectionLayer = nil
            
            // Recreate the layer
            let newLayer = LayerBuilder.shared.createLayer(from: sticker, canvasSize: canvasSize)
            canvasBgView.layer.addSublayer(newLayer)
            
            // Update sticker reference
            sticker.layer = newLayer
            
            // Recreate reflection if needed
            if sticker.hasReflection {
                let reflectionLayer = createReflectionLayer(for: newLayer)
                canvasBgView.layer.insertSublayer(reflectionLayer, below: newLayer)
                sticker.reflectionLayer = reflectionLayer
            }
            
            // Update in manager
            stickerManager.updateSticker(sticker)
        }
        
        // Restore selection highlighting
        if let selectedSticker = stickerManager.selectedSticker {
            highlightSelectedSticker()
        }
        
        // Reapply animations
        animateAllStickers()
        
        CATransaction.commit()
    }
}

// MARK: - UICollectionView Delegate and DataSource
extension BCAINewCanvasViewController: UICollectionViewDelegate,
                                       UICollectionViewDataSource,
                                       UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return canvasDatasource.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            guard let originalCanvasCell = canvasCollectionView.dequeueReusableCell(withReuseIdentifier: "BCAICanvasOriginalCollectionViewCell", for: indexPath) as? BCAICanvasOriginalCollectionViewCell
            else { return BCAICanvasCollectionViewCell() }
            originalCanvasCell.originalCanvasConfigure(bounds: bounds)
            return originalCanvasCell
        } else {
            guard let cell = canvasCollectionView.dequeueReusableCell(withReuseIdentifier: "BCAICanvasCollectionViewCell",
                                                                      for: indexPath) as? BCAICanvasCollectionViewCell
            else { return BCAICanvasCollectionViewCell() }
            let imageName = canvasDatasource[indexPath.row].inActive
            if let img = UIImage(named: imageName) {
                cell.thumbImage = img
                cell.canvasImgView.image = img
            }
            let selImageName = canvasDatasource[indexPath.row].active
            if let img = UIImage(named: selImageName) {
                cell.selectedThumbImage = img
            }
            
            if canvasStateModel.lastSelectedIndex == indexPath.row {
                cell.isSelected = true
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let h = canvasCollectionView.bounds.height / 1.3
        let w = canvasCollectionView.bounds.width / 6.0
        return CGSize(width: floor(w), height: h)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        
        canvasCollectionView.scrollToItem(at: indexPath,
                                          at: .centeredHorizontally,
                                          animated: true)
        
        canvasStateModel.selectedCanvas = indexPath.row
        
        // Changed canvas
        let ratioW = canvasDatasource[indexPath.row].ratioW
        let ratioH = canvasDatasource[indexPath.row].ratioH
        canvasStateModel.filterTransfromScale = 1.0
        
        if indexPath.row == 0 {
            canvasBgView.frame = bounds
            imageView.frame = CGRect(origin: .zero, size: bounds.size)
            canvasStateModel.isOrginal = true
            canvasStateModel.isDiffrent = false
            
        } else if indexPath.row == 4 {
            canvasFrameChangedWithX(ratioW: ratioW, ratioH: ratioH)
        } else {
            canvasFrameChangedWithY(ratioW: ratioW, ratioH: ratioH)
        }
        
        changeImageCanvas()
        canvasStateModel.lastSelectedIndex = indexPath.row
        
        // Update sticker positions after canvas change
        updateAllStickersForCanvasSizeChange()
    }
}

// MARK: - UIGestureRecognizerDelegate
//extension BCAINewCanvasViewController: UIGestureRecognizerDelegate {
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
//                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        // Allow simultaneous recognition of pinch, rotation, and pan gestures
//        return true
//    }
//}

// MARK: - CGPoint Extension for Relative Positioning
//extension CGPoint {
//    func relativePosition(for canvasSize: CGSize) -> CGPoint {
//        return CGPoint(x: self.x / canvasSize.width, y: self.y / canvasSize.height)
//    }
//
//    func absolutePosition(for canvasSize: CGSize) -> CGPoint {
//        return CGPoint(x: self.x * canvasSize.width, y: self.y * canvasSize.height)
//    }
//}
