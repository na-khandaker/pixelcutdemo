//
//  VideoManager.swift
//  LayerDemo
//
//  Created by BCL Device 5 on 8/1/26.
//

import UIKit
import AVFoundation

class VideoManager {
    
    // MARK: - Properties
    private let DURATION: TimeInterval = 1.2 // Match your animation duration
    
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
        
        return CGSize(width: width, height: height)
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
        
        let scaleX = videoSize.width / canvasView.bounds.width
        let scaleY = videoSize.height / canvasView.bounds.height
        
        // Create layers for each sticker based on the sticker manager
        for sticker in stickerManager.allStickers {
            let videoStickerLayer = createVideoStickerLayer(
                from: sticker,
                currentAnimation: currentAnimation,
                scaleX: scaleX,
                scaleY: scaleY,
                videoSize: videoSize
            )
            overlayLayer.addSublayer(videoStickerLayer)
        }
        
        return overlayLayer
    }
    
    private func createVideoStickerLayer(
        from sticker: StickerModel,
        currentAnimation: AnimationType,
        scaleX: CGFloat,
        scaleY: CGFloat,
        videoSize: CGSize
    ) -> CALayer {
        let layer = CALayer()
        
        // Get original layer frame or use sticker position
        let originalFrame: CGRect
        if let stickerLayer = sticker.layer {
            originalFrame = stickerLayer.frame
        } else {
            // If no layer, use sticker's position and size
            originalFrame = CGRect(
                x: sticker.position.x - sticker.size.width / 2,
                y: sticker.position.y - sticker.size.height / 2,
                width: sticker.size.width,
                height: sticker.size.height
            )
        }
        
        // Scale position and size for video
        layer.frame = CGRect(
            x: originalFrame.origin.x * scaleX,
            y: originalFrame.origin.y * scaleY,
            width: originalFrame.width * scaleX,
            height: originalFrame.height * scaleY
        )
        
        // Apply rotation and scale from sticker
        layer.transform = CATransform3DMakeRotation(sticker.rotation, 0, 0, 1)
        layer.transform = CATransform3DScale(layer.transform, sticker.scale, sticker.scale, 1)
        
        // Set content based on sticker type
        if sticker.type == .image, let cgImage = sticker.image?.cgImage {
            layer.contents = cgImage
            layer.contentsGravity = .resizeAspect
        } else if let color = sticker.color {
            layer.backgroundColor = color.cgColor
        }
        
        // Apply the correct animation based on sticker type and animation type
        if sticker.type == .line {
            // For lines, apply line growth animation
            applyLineAnimation(to: layer, sticker: sticker, videoSize: videoSize)
        } else {
            // For images and other stickers, apply the selected animation
            applyStickerAnimation(
                to: layer,
                animationType: currentAnimation,
                sticker: sticker,
                videoSize: videoSize
            )
        }
        
        return layer
    }
    
    private func applyLineAnimation(to layer: CALayer, sticker: StickerModel, videoSize: CGSize) {
        guard let edge = sticker.initialEdge else { return }
        
        let animation = CABasicAnimation()
        
        switch edge {
        case .top, .bottom:
            // Horizontal line growth
            animation.keyPath = "bounds.size.width"
            animation.fromValue = 0
            animation.toValue = videoSize.width
        case .left, .right:
            // Vertical line growth
            animation.keyPath = "bounds.size.height"
            animation.fromValue = 0
            animation.toValue = videoSize.height
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
            applyRevealUpAnimation(to: layer, sticker: sticker, videoSize: videoSize)
        case .RevealDown:
            applyRevealDownAnimation(to: layer, sticker: sticker, videoSize: videoSize)
        case .RevealLeft:
            applyRevealLeftAnimation(to: layer, sticker: sticker, videoSize: videoSize)
        case .RevealRight:
            applyRevealRightAnimation(to: layer, sticker: sticker, videoSize: videoSize)
        case .DriftUp:
            applyDriftUpAnimation(to: layer, sticker: sticker, videoSize: videoSize)
        case .DriftDown:
            applyDriftDownAnimation(to: layer, sticker: sticker, videoSize: videoSize)
        case .DriftLeft:
            applyDriftLeftAnimation(to: layer, sticker: sticker, videoSize: videoSize)
        case .DriftRight:
            applyDriftRightAnimation(to: layer, sticker: sticker, videoSize: videoSize)
        case .Fade:
            applyFadeAnimation(to: layer)
        case .Scale:
            applyScaleAnimation(to: layer)
        case .None:
            // No animation
            break
        }
    }
    
    // MARK: - Reveal Animations
    
    private func applyRevealUpAnimation(to layer: CALayer, sticker: StickerModel, videoSize: CGSize) {
        // Start from bottom, reveal upward
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
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        maskLayer.add(animation, forKey: "revealUp")
    }
    
    private func applyRevealDownAnimation(to layer: CALayer, sticker: StickerModel, videoSize: CGSize) {
        // Start from top, reveal downward
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
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        maskLayer.add(animation, forKey: "revealDown")
    }
    
    private func applyRevealLeftAnimation(to layer: CALayer, sticker: StickerModel, videoSize: CGSize) {
        // Start from right, reveal leftward
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
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        maskLayer.add(animation, forKey: "revealLeft")
    }
    
    private func applyRevealRightAnimation(to layer: CALayer, sticker: StickerModel, videoSize: CGSize) {
        // Start from left, reveal rightward
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
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        maskLayer.add(animation, forKey: "revealRight")
    }
    
    // MARK: - Drift Animations
    
    private func applyDriftUpAnimation(to layer: CALayer, sticker: StickerModel, videoSize: CGSize) {
        let animation = CABasicAnimation(keyPath: "position.y")
        animation.fromValue = layer.position.y + 100
        animation.toValue = layer.position.y
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        layer.add(animation, forKey: "driftUp")
    }
    
    private func applyDriftDownAnimation(to layer: CALayer, sticker: StickerModel, videoSize: CGSize) {
        let animation = CABasicAnimation(keyPath: "position.y")
        animation.fromValue = layer.position.y - 100
        animation.toValue = layer.position.y
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        layer.add(animation, forKey: "driftDown")
    }
    
    private func applyDriftLeftAnimation(to layer: CALayer, sticker: StickerModel, videoSize: CGSize) {
        let animation = CABasicAnimation(keyPath: "position.x")
        animation.fromValue = layer.position.x + 100
        animation.toValue = layer.position.x
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        layer.add(animation, forKey: "driftLeft")
    }
    
    private func applyDriftRightAnimation(to layer: CALayer, sticker: StickerModel, videoSize: CGSize) {
        let animation = CABasicAnimation(keyPath: "position.x")
        animation.fromValue = layer.position.x - 100
        animation.toValue = layer.position.x
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        layer.add(animation, forKey: "driftRight")
    }
    
    // MARK: - Basic Animations
    
    private func applyFadeAnimation(to layer: CALayer) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
        layer.add(animation, forKey: "fade")
    }
    
    private func applyScaleAnimation(to layer: CALayer) {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = DURATION
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        
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
