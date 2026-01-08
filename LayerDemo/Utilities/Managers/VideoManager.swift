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
        let overlayLayer = createOverlayLayer(from: canvasView, videoSize: videoSize)
        
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
    
    private func createOverlayLayer(from canvasView: UIView, videoSize: CGSize) -> CALayer {
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
        
        // Get all sublayers from canvasView
        guard let canvasSublayers = canvasView.layer.sublayers else {
            return overlayLayer
        }
        
        let scaleX = videoSize.width / canvasView.bounds.width
        let scaleY = videoSize.height / canvasView.bounds.height
        
        // Create a copy of each layer with proper scaling
        for originalLayer in canvasSublayers {
            let videoLayer = createVideoLayer(from: originalLayer, scaleX: scaleX, scaleY: scaleY)
            overlayLayer.addSublayer(videoLayer)
        }
        
        return overlayLayer
    }
    
    private func createVideoLayer(from originalLayer: CALayer, scaleX: CGFloat, scaleY: CGFloat) -> CALayer {
        let videoLayer = CALayer()
        
        // Copy basic properties
        videoLayer.contents = originalLayer.contents
        videoLayer.backgroundColor = originalLayer.backgroundColor
        videoLayer.opacity = originalLayer.opacity
        videoLayer.cornerRadius = originalLayer.cornerRadius
        videoLayer.borderWidth = originalLayer.borderWidth
        videoLayer.borderColor = originalLayer.borderColor
        videoLayer.masksToBounds = originalLayer.masksToBounds
        videoLayer.contentsGravity = originalLayer.contentsGravity
        videoLayer.contentsScale = originalLayer.contentsScale
        
        // Scale position and size for video
        videoLayer.frame = CGRect(
            x: originalLayer.frame.origin.x * scaleX,
            y: originalLayer.frame.origin.y * scaleY,
            width: originalLayer.frame.width * scaleX,
            height: originalLayer.frame.height * scaleY
        )
        
        // Apply transform
        videoLayer.transform = originalLayer.transform
        
        // Copy all animations with proper timing for video export
        copyAnimations(from: originalLayer, to: videoLayer)
        
        // Recursively add sublayers if this layer has any
        if let originalSublayers = originalLayer.sublayers {
            for originalSublayer in originalSublayers {
                let videoSublayer = createVideoLayer(from: originalSublayer, scaleX: scaleX, scaleY: scaleY)
                videoLayer.addSublayer(videoSublayer)
            }
        }
        
        return videoLayer
    }
    
    private func copyAnimations(from sourceLayer: CALayer, to destinationLayer: CALayer) {
        guard let animationKeys = sourceLayer.animationKeys() else { return }
        
        for key in animationKeys {
            if let animation = sourceLayer.animation(forKey: key)?.copy() as? CAAnimation {
                // Configure animation for video export
                animation.beginTime = AVCoreAnimationBeginTimeAtZero
                animation.isRemovedOnCompletion = false
                animation.fillMode = .forwards
                
                // Handle special animations like CAEmitterLayer
                if key == "lineGrowth" || key == "pulse" || key == "scale" {
                    // Ensure animations play from the beginning
                    animation.beginTime = AVCoreAnimationBeginTimeAtZero
                }
                
                // Handle CAEmitterLayer animations
                if sourceLayer is CAEmitterLayer {
                    // For emitter layers, we need to handle them specially
                    handleEmitterLayerAnimations(sourceLayer: sourceLayer, destinationLayer: destinationLayer)
                    continue
                }
                
                destinationLayer.add(animation, forKey: key)
            }
        }
    }
    
    private func handleEmitterLayerAnimations(sourceLayer: CALayer, destinationLayer: CALayer) {
        guard let emitterSource = sourceLayer as? CAEmitterLayer,
              let emitterDest = destinationLayer as? CAEmitterLayer else { return }
        
        // Copy emitter properties
        emitterDest.emitterPosition = emitterSource.emitterPosition
        emitterDest.emitterSize = emitterSource.emitterSize
        emitterDest.emitterShape = emitterSource.emitterShape
        emitterDest.emitterMode = emitterSource.emitterMode
        emitterDest.renderMode = emitterSource.renderMode
        emitterDest.emitterCells = emitterSource.emitterCells?.map { copyEmitterCell($0) }
        emitterDest.beginTime = AVCoreAnimationBeginTimeAtZero
        emitterDest.birthRate = emitterSource.birthRate
    }
    
    private func copyEmitterCell(_ cell: CAEmitterCell) -> CAEmitterCell {
        let newCell = CAEmitterCell()
        
        // Copy all properties
        newCell.contents = cell.contents
        newCell.birthRate = cell.birthRate
        newCell.lifetime = cell.lifetime
        newCell.lifetimeRange = cell.lifetimeRange
        newCell.velocity = cell.velocity
        newCell.velocityRange = cell.velocityRange
        newCell.emissionLongitude = cell.emissionLongitude
        newCell.emissionRange = cell.emissionRange
        newCell.spin = cell.spin
        newCell.spinRange = cell.spinRange
        newCell.scale = cell.scale
        newCell.scaleRange = cell.scaleRange
        newCell.scaleSpeed = cell.scaleSpeed
        newCell.color = cell.color
        newCell.redRange = cell.redRange
        newCell.greenRange = cell.greenRange
        newCell.blueRange = cell.blueRange
        newCell.alphaRange = cell.alphaRange
        newCell.redSpeed = cell.redSpeed
        newCell.greenSpeed = cell.greenSpeed
        newCell.blueSpeed = cell.blueSpeed
        newCell.alphaSpeed = cell.alphaSpeed
        
        return newCell
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
