import UIKit
import AVFoundation

class VideoManager {
    
    // MARK: - Properties
    private let DURATION: TimeInterval = 1.2
    private var exportCanvasSize: CGSize = .zero
    
    // MARK: - Public Methods
    func exportVideoWithLayerAnimation(
        blankVideoURL: URL,
        canvasView: UIView,
        stickerManager: StickerManager,
        currentAnimation: AnimationType,
        onComplete: @escaping (URL?) -> Void
    ) {
        // Create a composition with repeated blank video
        guard let repeatedComposition = createRepeatedVideoComposition(
            from: blankVideoURL,
            targetDuration: DURATION
        ) else {
            print("Failed to create repeated video composition")
            onComplete(nil)
            return
        }
        
        // Get the asset track
        guard let assetTrack = repeatedComposition.tracks(withMediaType: .video).first else {
            print("No video track found")
            onComplete(nil)
            return
        }
        
        // Get the final video size based on canvas aspect ratio
        let videoSize = getVideoSize(from: canvasView)
        
        // Create the video composition with canvas layers
        guard let videoComposition = createVideoComposition(
            composition: repeatedComposition,
            assetTrack: assetTrack,
            canvasView: canvasView,
            stickerManager: stickerManager,
            currentAnimation: currentAnimation,
            videoSize: videoSize
        ) else {
            print("Failed to create video composition")
            onComplete(nil)
            return
        }
        
        // Export the video
        exportVideo(
            composition: repeatedComposition,
            videoComposition: videoComposition,
            videoSize: videoSize,
            onComplete: onComplete
        )
    }
    
    // MARK: - Private Methods
    private func createRepeatedVideoComposition(
        from videoURL: URL,
        targetDuration: TimeInterval
    ) -> AVMutableComposition? {
        let asset = AVURLAsset(url: videoURL)
        let composition = AVMutableComposition()
        
        guard
            let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ),
            let assetVideoTrack = asset.tracks(withMediaType: .video).first
        else {
            print("Failed to create composition tracks")
            return nil
        }
        
        let videoDuration = asset.duration
        let targetCMTime = CMTime(seconds: targetDuration, preferredTimescale: 600)
        var currentTime = CMTime.zero
        
        do {
            // Repeat the blank video until we reach target duration
            while currentTime < targetCMTime {
                let timeRange = CMTimeRange(start: .zero, duration: videoDuration)
                let insertDuration = min(videoDuration, CMTimeSubtract(targetCMTime, currentTime))
                let insertRange = CMTimeRange(start: .zero, duration: insertDuration)
                
                try compositionVideoTrack.insertTimeRange(insertRange, of: assetVideoTrack, at: currentTime)
                currentTime = CMTimeAdd(currentTime, insertDuration)
            }
            
            // Add audio if available
            if let assetAudioTrack = asset.tracks(withMediaType: .audio).first,
               let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
               ) {
                currentTime = CMTime.zero
                while currentTime < targetCMTime {
                    let timeRange = CMTimeRange(start: .zero, duration: videoDuration)
                    let insertDuration = min(videoDuration, CMTimeSubtract(targetCMTime, currentTime))
                    let insertRange = CMTimeRange(start: .zero, duration: insertDuration)
                    
                    try compositionAudioTrack.insertTimeRange(insertRange, of: assetAudioTrack, at: currentTime)
                    currentTime = CMTimeAdd(currentTime, insertDuration)
                }
            }
        } catch {
            print("Error inserting time ranges: \(error)")
            return nil
        }
        
        compositionVideoTrack.preferredTransform = assetVideoTrack.preferredTransform
        return composition
    }
    
    private func getVideoSize(from canvasView: UIView) -> CGSize {
        // Use the canvasView's aspect ratio to determine video size
        let aspectRatio = canvasView.bounds.width / canvasView.bounds.height
        
        // Standard video sizes with same aspect ratio
        let baseHeight: CGFloat = 1920
        let baseWidth = baseHeight * aspectRatio
        
        // Round to even numbers (required by video codecs)
        let width = (baseWidth / 2).rounded() * 2
        let height = (baseHeight / 2).rounded() * 2
        
        exportCanvasSize = CGSize(width: width, height: height)
        return exportCanvasSize
    }
    
    private func createVideoComposition(
        composition: AVMutableComposition,
        assetTrack: AVAssetTrack,
        canvasView: UIView,
        stickerManager: StickerManager,
        currentAnimation: AnimationType,
        videoSize: CGSize
    ) -> AVMutableVideoComposition? {
        
        // Create video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 60) // 60 FPS
        
        // Create video layer that will show the blank video
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        
        // Create overlay layer with all canvas layers
        let overlayLayer = createOverlayLayer(
            from: canvasView,
            stickerManager: stickerManager,
            currentAnimation: currentAnimation,
            videoSize: videoSize
        )
        overlayLayer.isGeometryFlipped = true
        
        // Create parent layer that combines video and overlay
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: videoSize)
        parentLayer.addSublayer(videoLayer) // Video layer at the bottom
        parentLayer.addSublayer(overlayLayer) // Canvas layers on top
        
        // Set up the animation tool with proper layering
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )
        
        // Create instructions
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(
            start: .zero,
            duration: composition.duration
        )
        
        let layerInstruction = compositionLayerInstruction(
            for: assetTrack as! AVCompositionTrack,
            transform: assetTrack.preferredTransform
        )
        instruction.layerInstructions = [layerInstruction]
        
        videoComposition.instructions = [instruction]
        
        return videoComposition
    }
    
    private func createOverlayLayer(
        from canvasView: UIView,
        stickerManager: StickerManager,
        currentAnimation: AnimationType,
        videoSize: CGSize
    ) -> CALayer {
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
        
        // Create layers for each sticker based on the sticker manager
        for sticker in stickerManager.allStickers {
            let videoStickerLayer = createVideoStickerLayer(
                from: sticker,
                currentAnimation: currentAnimation,
                canvasView: canvasView,
                videoSize: videoSize
            )
            overlayLayer.addSublayer(videoStickerLayer)
        }
        
        return overlayLayer
    }
    
    private func createVideoStickerLayer(
        from sticker: StickerModel,
        currentAnimation: AnimationType,
        canvasView: UIView,
        videoSize: CGSize
    ) -> CALayer {
        let layer = CALayer()
        
        // Calculate scale factors for converting canvas coordinates to video coordinates
        let canvasToVideoScaleX = videoSize.width / canvasView.bounds.width
        let canvasToVideoScaleY = videoSize.height / canvasView.bounds.height
        
        // Get sticker's absolute position on canvas
        let stickerAbsolutePosition = sticker.relativePosition.absolutePosition(for: canvasView.bounds.size)
        
        // Calculate video position (center of the sticker in video coordinates)
        let videoPositionX = stickerAbsolutePosition.x * canvasToVideoScaleX
        let videoPositionY = stickerAbsolutePosition.y * canvasToVideoScaleY
        
        // Calculate the unscaled size of the sticker (before applying sticker.scale)
        let unscaledWidth = sticker.size.width
        let unscaledHeight = sticker.size.height
        
        // Set the layer's anchor point to center
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        // Set position (center point)
        layer.position = CGPoint(x: videoPositionX, y: videoPositionY)
        
        // Set bounds with unscaled size
        layer.bounds = CGRect(x: 0, y: 0, width: unscaledWidth, height: unscaledHeight)
        
        // Apply the scale from sticker model (this is the user-applied scale)
        let stickerScale = sticker.scale
        var transform = CATransform3DMakeScale(stickerScale, stickerScale, 1)
        
        // Apply rotation
        transform = CATransform3DRotate(transform, sticker.rotation, 0, 0, 1)
        
        // Apply the combined transform
        layer.transform = transform
        
        // Apply opacity
        layer.opacity = Float(sticker.opacity)
        
        // Set content based on sticker type
        switch sticker.type {
        case .text:
            if let textSticker = sticker as? TextStickerModel {
                let textLayer = CATextLayer()
                textLayer.string = textSticker.text
                textLayer.font = CTFontCreateWithName((textSticker.fontName ?? "Helvetica") as CFString, textSticker.fontSize, nil)
                textLayer.fontSize = textSticker.fontSize
                textLayer.foregroundColor = textSticker.textColor.cgColor
                textLayer.alignmentMode = .center
                textLayer.isWrapped = true
                textLayer.frame = layer.bounds
                textLayer.contentsScale = UIScreen.main.scale
                
                // Apply text background if needed
//                if let bgColor = textSticker.backgroundColor {
//                    layer.backgroundColor = bgColor.cgColor
//                    layer.cornerRadius = 8
//                }
                
                layer.addSublayer(textLayer)
            }
            
        case .image:
            if let imageSticker = sticker as? ImageStickerModel,
               let cgImage = imageSticker.image.cgImage {
                layer.contents = cgImage
                layer.contentsGravity = .resizeAspect
                layer.masksToBounds = true
                
                // Apply rounded corners if needed
//                if imageSticker.cornerRadius > 0 {
//                    layer.cornerRadius = imageSticker.cornerRadius
//                }
            }
            
        case .shape:
            if let shapeSticker = sticker as? ShapeStickerModel {
                //layer.backgroundColor = shapeSticker.color.cgColor
                layer.masksToBounds = true
                
                // Apply shape-specific properties
                switch shapeSticker.shapeType {
                case .circle:
                    layer.cornerRadius = min(layer.bounds.width, layer.bounds.height) / 2
                case .rectangle:
                    layer.cornerRadius = shapeSticker.cornerRadius
//                case .roundedRectangle:
//                  layer.cornerRadius = shapeSticker.cornerRadius
                case .roundedRect:
                    layer.cornerRadius = shapeSticker.cornerRadius
                }
            }
            
        case .line:
            if let lineSticker = sticker as? LineStickerModel {
                layer.backgroundColor = lineSticker.color?.cgColor
                
                // For lines, adjust bounds based on orientation
                if lineSticker.isHorizontal ?? true {
                    layer.bounds.size.height = lineSticker.lineWidth
                } else {
                    layer.bounds.size.width = lineSticker.lineWidth
                }
            }
        }
        
        // Add reflection if needed
        if sticker.hasReflection {
            addVideoReflectionLayer(to: layer, sticker: sticker)
        }
        
        // Apply the correct animation based on sticker type and animation type
        if sticker.type == .line {
            // For lines, apply line growth animation
            applyLineAnimation(to: layer, sticker: sticker, videoSize: videoSize)
        } else {
            // For other stickers, apply the selected animation
            applyStickerAnimation(
                to: layer,
                animationType: currentAnimation,
                sticker: sticker,
                videoSize: videoSize
            )
        }
        
        return layer
    }
    
    private func addVideoReflectionLayer(to layer: CALayer, sticker: StickerModel) {
        let reflectionLayer = CALayer()
        
        // Copy the main layer's content
        if let contents = layer.contents {
            reflectionLayer.contents = contents
        } else {
            reflectionLayer.backgroundColor = layer.backgroundColor
        }
        
        // Position reflection below the main layer
        let reflectionHeight = layer.bounds.height * 0.5
        
        reflectionLayer.bounds = CGRect(
            x: 0,
            y: 0,
            width: layer.bounds.width,
            height: reflectionHeight
        )
        
        // Set anchor point to top
        reflectionLayer.anchorPoint = CGPoint(x: 0.5, y: 0)
        
        // Position at bottom of main layer
        reflectionLayer.position = CGPoint(
            x: layer.bounds.width / 2,
            y: layer.bounds.height
        )
        
        // Apply vertical flip
        reflectionLayer.transform = CATransform3DMakeScale(1, -1, 1)
        
        // Apply opacity
        reflectionLayer.opacity = Float(sticker.opacity * 0.5)
        
        // Create gradient mask for fade effect
        let gradientMask = CAGradientLayer()
        gradientMask.frame = reflectionLayer.bounds
        gradientMask.colors = [
            UIColor.white.withAlphaComponent(0.8).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor
        ]
        gradientMask.locations = [0.0, 1.0]
        gradientMask.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientMask.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        reflectionLayer.mask = gradientMask
        layer.addSublayer(reflectionLayer)
    }
    
    private func applyLineAnimation(to layer: CALayer, sticker: StickerModel, videoSize: CGSize) {
        guard let lineSticker = sticker as? LineStickerModel,
              let edge = lineSticker.initialEdge else { return }
        
        let animation = CABasicAnimation()
        
        switch edge {
        case .top, .bottom:
            // Horizontal line growth
            animation.keyPath = "bounds.size.width"
            animation.fromValue = 0
            animation.toValue = layer.bounds.width
        case .left, .right:
            // Vertical line growth
            animation.keyPath = "bounds.size.height"
            animation.fromValue = 0
            animation.toValue = layer.bounds.height
        }
        
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        layer.add(animation, forKey: "lineGrowth")
    }
    
    private func applyStickerAnimation(
        to layer: CALayer,
        animationType: AnimationType,
        sticker: StickerModel,
        videoSize: CGSize
    ) {
        // Apply different animations based on the animation type
        switch animationType {
        case .RevealUp:
            applyRevealUpAnimation(to: layer, duration: DURATION)
        case .RevealDown:
            applyRevealDownAnimation(to: layer, duration: DURATION)
        case .RevealLeft:
            applyRevealLeftAnimation(to: layer, duration: DURATION)
        case .RevealRight:
            applyRevealRightAnimation(to: layer, duration: DURATION)
        case .DriftUp:
            applyDriftUpAnimation(to: layer, duration: DURATION)
        case .DriftDown:
            applyDriftDownAnimation(to: layer, duration: DURATION)
        case .DriftLeft:
            applyDriftLeftAnimation(to: layer, duration: DURATION)
        case .DriftRight:
            applyDriftRightAnimation(to: layer, duration: DURATION)
        case .Fade:
            applyFadeAnimation(to: layer, duration: DURATION)
        case .Scale:
            applyScaleAnimation(to: layer, duration: DURATION)
        case .None:
            // No animation
            break
        }
    }
    
    // MARK: - Animation Helper Methods
    
    private func applyRevealUpAnimation(to layer: CALayer, duration: TimeInterval) {
        let maskLayer = CAShapeLayer()
        let initialPath = UIBezierPath(rect: CGRect(
            x: 0,
            y: layer.bounds.height,
            width: layer.bounds.width,
            height: 0
        )).cgPath
        let finalPath = UIBezierPath(rect: CGRect(
            x: 0,
            y: 0,
            width: layer.bounds.width,
            height: layer.bounds.height
        )).cgPath
        
        maskLayer.path = initialPath
        layer.mask = maskLayer
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = initialPath
        animation.toValue = finalPath
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        maskLayer.add(animation, forKey: "revealUp")
    }
    
    private func applyRevealDownAnimation(to layer: CALayer, duration: TimeInterval) {
        let maskLayer = CAShapeLayer()
        let initialPath = UIBezierPath(rect: CGRect(
            x: 0,
            y: 0,
            width: layer.bounds.width,
            height: 0
        )).cgPath
        let finalPath = UIBezierPath(rect: CGRect(
            x: 0,
            y: 0,
            width: layer.bounds.width,
            height: layer.bounds.height
        )).cgPath
        
        maskLayer.path = initialPath
        layer.mask = maskLayer
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = initialPath
        animation.toValue = finalPath
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        maskLayer.add(animation, forKey: "revealDown")
    }
    
    private func applyRevealLeftAnimation(to layer: CALayer, duration: TimeInterval) {
        let maskLayer = CAShapeLayer()
        let initialPath = UIBezierPath(rect: CGRect(
            x: layer.bounds.width,
            y: 0,
            width: 0,
            height: layer.bounds.height
        )).cgPath
        let finalPath = UIBezierPath(rect: CGRect(
            x: 0,
            y: 0,
            width: layer.bounds.width,
            height: layer.bounds.height
        )).cgPath
        
        maskLayer.path = initialPath
        layer.mask = maskLayer
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = initialPath
        animation.toValue = finalPath
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        maskLayer.add(animation, forKey: "revealLeft")
    }
    
    private func applyRevealRightAnimation(to layer: CALayer, duration: TimeInterval) {
        let maskLayer = CAShapeLayer()
        let initialPath = UIBezierPath(rect: CGRect(
            x: 0,
            y: 0,
            width: 0,
            height: layer.bounds.height
        )).cgPath
        let finalPath = UIBezierPath(rect: CGRect(
            x: 0,
            y: 0,
            width: layer.bounds.width,
            height: layer.bounds.height
        )).cgPath
        
        maskLayer.path = initialPath
        layer.mask = maskLayer
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = initialPath
        animation.toValue = finalPath
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        maskLayer.add(animation, forKey: "revealRight")
    }
    
    private func applyDriftUpAnimation(to layer: CALayer, duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "position.y")
        animation.fromValue = layer.position.y + 100
        animation.toValue = layer.position.y
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        layer.add(animation, forKey: "driftUp")
    }
    
    private func applyDriftDownAnimation(to layer: CALayer, duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "position.y")
        animation.fromValue = layer.position.y - 100
        animation.toValue = layer.position.y
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        layer.add(animation, forKey: "driftDown")
    }
    
    private func applyDriftLeftAnimation(to layer: CALayer, duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "position.x")
        animation.fromValue = layer.position.x + 100
        animation.toValue = layer.position.x
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        layer.add(animation, forKey: "driftLeft")
    }
    
    private func applyDriftRightAnimation(to layer: CALayer, duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "position.x")
        animation.fromValue = layer.position.x - 100
        animation.toValue = layer.position.x
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        layer.add(animation, forKey: "driftRight")
    }
    
    private func applyFadeAnimation(to layer: CALayer, duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = layer.opacity
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        layer.add(animation, forKey: "fade")
    }
    
    private func applyScaleAnimation(to layer: CALayer, duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        // Apply to current transform
        layer.add(animation, forKey: "scale")
    }
    
    private func compositionLayerInstruction(
        for track: AVCompositionTrack,
        transform: CGAffineTransform
    ) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        instruction.setTransform(transform, at: .zero)
        return instruction
    }
    
    private func exportVideo(
        composition: AVMutableComposition,
        videoComposition: AVMutableVideoComposition,
        videoSize: CGSize,
        onComplete: @escaping (URL?) -> Void
    ) {
        guard let export = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            print("Cannot create export session.")
            onComplete(nil)
            return
        }
        
        let videoName = "exported_video_\(Date().timeIntervalSince1970)"
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(videoName)
            .appendingPathExtension("mov")
        
        export.videoComposition = videoComposition
        export.outputFileType = .mov
        export.outputURL = exportURL
        
        export.exportAsynchronously {
            DispatchQueue.main.async {
                switch export.status {
                case .completed:
                    print("✅ Video exported successfully to: \(exportURL)")
                    onComplete(exportURL)
                case .failed:
                    print("❌ Export failed: \(export.error?.localizedDescription ?? "Unknown error")")
                    onComplete(nil)
                case .cancelled:
                    print("Export cancelled")
                    onComplete(nil)
                default:
                    print("Export status: \(export.status.rawValue)")
                    onComplete(nil)
                }
            }
        }
    }
}
