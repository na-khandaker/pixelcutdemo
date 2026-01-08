//
//  VideoWriter.swift
//  LayerDemo
//
//  Created by BCL Device 5 on 6/1/26.
//

import AVFoundation
import CoreImage


class VideoWriter {
    private let videoWriter: AVAssetWriter
    private let videoWriterInput: AVAssetWriterInput
    private let pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor
    
    init(outputURL: URL, frameSize: CGSize, fps: Int32) {
        // Create video writer
        videoWriter = try! AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        // Configure video settings
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: frameSize.width,
            AVVideoHeightKey: frameSize.height
        ]
        
        videoWriterInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: videoSettings
        )
        videoWriterInput.expectsMediaDataInRealTime = false
        
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: frameSize.width,
            kCVPixelBufferHeightKey as String: frameSize.height
        ]
        
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes
        )
        
        videoWriter.add(videoWriterInput)
    }
    
    func startWriting() {
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)
    }
    
    func addImage(_ ciImage: CIImage, at presentationTime: CMTime) {
        guard videoWriterInput.isReadyForMoreMediaData else { return }
        
        if let pixelBuffer = createPixelBuffer(from: ciImage) {
            pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
        }
    }
    
    func finishWriting(completion: @escaping (Bool) -> Void) {
        videoWriterInput.markAsFinished()
        //videoWriter.finishWriting(completionHandler: completion)
    }
    
    private func createPixelBuffer(from ciImage: CIImage) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(ciImage.extent.width),
            Int(ciImage.extent.height),
            kCVPixelFormatType_32ARGB,
            attrs,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CIContext()
        context.render(ciImage, to: buffer)
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        return buffer
    }
}
