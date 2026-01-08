import UIKit
import Photos
import AVFoundation
import AVKit
import MobileCoreServices

class ViewController: UIViewController {
    
    // MARK: - Properties
    private var currentSelectedAnimation: AnimationType = .DriftUp
    private var stickerManager = StickerManager()
    private var imageCounter = 0
    
    // MARK: - IBOutlets
    @IBOutlet weak var animationCollectionView: UICollectionView!
    @IBOutlet weak var canvasView: UIView!
    //    @IBOutlet weak var addImageButton: UIButton!
    //    @IBOutlet weak var addLineButton: UIButton!
    //    @IBOutlet weak var deleteButton: UIButton!
    //    @IBOutlet weak var playButton: UIButton!
    //    @IBOutlet weak var exportButton: UIButton!
    
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
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupGestures()
        createInitialStickers()
        animateAllStickers()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        //setupCollectionView()
        //setupButtons()
    }
    
    private func setupCollectionView() {
        animationCollectionView.dataSource = self
        animationCollectionView.delegate = self
        if let nib = UINib(nibName: "AnimationCollectionViewCell", bundle: nil) as? UINib {
            animationCollectionView.register(nib, forCellWithReuseIdentifier: "AnimationCollectionViewCell")
        }
    }
    
    //    private func setupButtons() {
    //        addImageButton.addTarget(self, action: #selector(addImageTapped), for: .touchUpInside)
    //        addLineButton.addTarget(self, action: #selector(addLineTapped), for: .touchUpInside)
    //        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
    //        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
    //        exportButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
    //
    //        deleteButton.isHidden = true
    //
    //        // Style buttons
    //        [addImageButton, addLineButton, deleteButton, playButton, exportButton].forEach { button in
    //            button?.layer.cornerRadius = 8
    //            button?.layer.masksToBounds = true
    //        }
    //    }
    
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
    }
    
    private func createEdgeLines() {
        let canvasBounds = canvasView.bounds
        
        // Top line
        let topConfig = StickerConfiguration(
            position: CGPoint(x: 0, y: LINE_WIDTH / 2),
            size: CGSize(width: 1, height: LINE_WIDTH),
            edge: .top,
            zIndex: 0
        )
        let topSticker = StickerFactory.shared.createSticker(type: .line, configuration: topConfig)
        addStickerToCanvas(topSticker)
        
        // Bottom line
        let bottomConfig = StickerConfiguration(
            position: CGPoint(x: canvasBounds.width, y: canvasBounds.height - LINE_WIDTH / 2),
            size: CGSize(width: 1, height: LINE_WIDTH),
            edge: .bottom,
            zIndex: 1
        )
        let bottomSticker = StickerFactory.shared.createSticker(type: .line, configuration: bottomConfig)
        addStickerToCanvas(bottomSticker)
        
        // Left line
        let leftConfig = StickerConfiguration(
            position: CGPoint(x: LINE_WIDTH / 2, y: 0),
            size: CGSize(width: LINE_WIDTH, height: 1),
            edge: .left,
            zIndex: 2
        )
        let leftSticker = StickerFactory.shared.createSticker(type: .line, configuration: leftConfig)
        addStickerToCanvas(leftSticker)
        
        // Right line
        let rightConfig = StickerConfiguration(
            position: CGPoint(x: canvasBounds.width - LINE_WIDTH / 2, y: canvasBounds.height),
            size: CGSize(width: LINE_WIDTH, height: 1),
            edge: .right,
            zIndex: 3
        )
        let rightSticker = StickerFactory.shared.createSticker(type: .line, configuration: rightConfig)
        addStickerToCanvas(rightSticker)
    }
    
    private func createInitialImage() {
        guard let image = UIImage(named: "testImage") else { return }
        
        let size: CGFloat = canvasView.bounds.width / 3
        let config = StickerConfiguration(
            position: CGPoint(x: canvasView.bounds.width / 2, y: canvasView.bounds.height / 2),
            size: CGSize(width: size, height: size),
            image: image,
            zIndex: 10
        )
        
        let imageSticker = StickerFactory.shared.createSticker(type: .image, configuration: config)
        addStickerToCanvas(imageSticker)
    }
    
    // MARK: - Sticker Management
    private func addStickerToCanvas(_ sticker: StickerModel) {
        // Create layer
        let layer = LayerBuilder.shared.createLayer(from: sticker)
        canvasView.layer.addSublayer(layer)
        
        // Update sticker with layer reference
        var updatedSticker = sticker
        updatedSticker.layer = layer
        stickerManager.addSticker(updatedSticker)
        
        // Select the new sticker
        stickerManager.setSelectedSticker(withId: updatedSticker.id)
        updateDeleteButtonVisibility()
        highlightSelectedSticker()
    }
    
    private func updateStickerLayer(_ sticker: StickerModel) {
        guard let layer = sticker.layer else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        layer.position = sticker.position
        layer.bounds.size = sticker.size
        layer.transform = CATransform3DMakeRotation(sticker.rotation, 0, 0, 1)
        layer.transform = CATransform3DScale(layer.transform, sticker.scale, sticker.scale, 1)
        
        if sticker.type == .image, let cgImage = sticker.image?.cgImage {
            layer.contents = cgImage
        } else if let color = sticker.color {
            layer.backgroundColor = color.cgColor
        }
        
        CATransaction.commit()
    }
    
    private func removeSelectedSticker() {
        guard let selectedSticker = stickerManager.selectedSticker,
              let layer = selectedSticker.layer else { return }
        
        layer.removeFromSuperlayer()
        stickerManager.removeSticker(withId: selectedSticker.id)
        updateDeleteButtonVisibility()
    }
    
    // MARK: - Gesture Handlers
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: canvasView)
        
        // Find tapped sticker using manager's hit testing
        if let tappedSticker = stickerManager.getStickerAtPoint(location, in: canvasView) {
            stickerManager.setSelectedSticker(withId: tappedSticker.id)
            updateDeleteButtonVisibility()
            highlightSelectedSticker()
            return
        }
        
        // If tapped on empty space, clear selection
        stickerManager.clearSelection()
        updateDeleteButtonVisibility()
        removeHighlight()
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let selectedSticker = stickerManager.selectedSticker,
              let layer = selectedSticker.layer else { return }
        
        let translation = gesture.translation(in: canvasView)
        
        if gesture.state == .began {
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
        }
        
        if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
            lastPanPosition = nil
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let selectedSticker = stickerManager.selectedSticker else { return }
        
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
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let selectedSticker = stickerManager.selectedSticker else { return }
        
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
    }
    
    // MARK: - Button Actions
    @objc private func addImageTapped() {
        imageCounter += 1
        
        // For demo, use test image. In production, use image picker
        guard let image = UIImage(named: "testImage") else {
            showAlert(message: "Test image not found. Please add 'testImage' to your assets.")
            return
        }
        
        let size: CGFloat = canvasView.bounds.width / 4
        let randomX = CGFloat.random(in: size/2...(canvasView.bounds.width - size/2))
        let randomY = CGFloat.random(in: size/2...(canvasView.bounds.height - size/2))
        
        let config = StickerConfiguration(
            position: CGPoint(x: randomX, y: randomY),
            size: CGSize(width: size, height: size),
            image: image,
            zIndex: 10 + imageCounter
        )
        
        let imageSticker = StickerFactory.shared.createSticker(type: .image, configuration: config)
        addStickerToCanvas(imageSticker)
    }
    
    @objc private func addLineTapped() {
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
        
        let config = StickerConfiguration(
            position: CGPoint(x: randomX, y: randomY),
            size: size,
            color: randomColor,
            zIndex: 5
        )
        
        let lineSticker = StickerFactory.shared.createSticker(type: .line, configuration: config)
        addStickerToCanvas(lineSticker)
    }
    
    @objc private func deleteTapped() {
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
        
        // For lines with specific edge positions, constrain differently
        //        if sticker.type == .line, let edge = sticker.initialEdge {
        //            switch edge {
        //            case .top:
        //                constrainedPosition.x = position.x
        //                constrainedPosition.y = LINE_WIDTH / 2
        //            case .bottom:
        //                constrainedPosition.x = position.x
        //                constrainedPosition.y = canvasBounds.height - LINE_WIDTH / 2
        //            case .left:
        //                constrainedPosition.x = LINE_WIDTH / 2
        //                constrainedPosition.y = position.y
        //            case .right:
        //                constrainedPosition.x = canvasBounds.width - LINE_WIDTH / 2
        //                constrainedPosition.y = position.y
        //            }
        //        } else {
        
        // For other stickers, keep within canvas
        let minX = layerBounds.width * sticker.scale / 2
        let maxX = canvasBounds.width - (layerBounds.width * sticker.scale / 2)
        let minY = layerBounds.height * sticker.scale / 2
        let maxY = canvasBounds.height - (layerBounds.height * sticker.scale / 2)
        
        constrainedPosition.x = min(max(position.x, minX), maxX)
        constrainedPosition.y = min(max(position.y, minY), maxY)
        //}
        
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
    
    private func updateDeleteButtonVisibility() {
        //deleteButton.isHidden = stickerManager.selectedSticker == nil
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Info", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Animation Methods
    private func animateAllStickers() {
        // Animate edge lines
        for sticker in stickerManager.lineStickers {
            if let layer = sticker.layer, let edge = sticker.initialEdge {
                animateLineGrowth(layer, edge: edge)
            }
        }
        
        // Animate all image stickers with current animation type
        for sticker in stickerManager.imageStickers {
            if let layer = sticker.layer {
                LayerBuilder.shared.applyAnimation(to: layer, animationType: currentSelectedAnimation, duration: DURATION)
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
    
    // MARK: - Play/Reset
    private func resetAndReanimate() {
        // Save current states
        let savedStickers = stickerManager.allStickers
        
        // Remove all layers and animations
        canvasView.layer.sublayers?.forEach {
            $0.removeAllAnimations()
            $0.removeFromSuperlayer()
        }
        
        // Clear sticker manager
        //let stickerManagerCopy = stickerManager
        stickerManager = StickerManager()
        
        // Recreate all stickers with saved positions
        for var sticker in savedStickers {
            sticker.layer = nil // Clear old layer reference
            addStickerToCanvas(sticker)
        }
        
        // Reapply animations
        animateAllStickers()
    }
    
    // MARK: - Export
    private func exportAnimatedVideo() {
//        PHPhotoLibrary.requestAuthorization { [weak self] status in
//            DispatchQueue.main.async {
//                guard let self = self else { return }
//                
//                if status == .authorized {
//                    self.performVideoExport()
//                } else {
//                    self.showPhotoLibraryAccessAlert()
//                }
//            }
//        }
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

