//
//  HTMLStreamManager.swift
//  ScreenMirroring
//
//  Created by Vital on 12.11.21.
//

import Foundation
import CoreMedia
import CoreImage

class HTMLStreamManager { 
    private var httpServer: HTTPServer?
    private var encoder: JPEGEncoder
    private let ciContext = CIContext(options: nil)
    private var didSetup = false 
    
    init(encoder: JPEGEncoder) {
        self.encoder = encoder
        self.encoder.delegate = self
        setupHTTPServer()
    }
    
    private func setupHTTPServer() {
        httpServer = HTTPServer() 
        httpServer?.start()
    }
    
    func encode(_ sampleBuffer: CMSampleBuffer, resolution: ResolutionType, orientation: CGImagePropertyOrientation) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }
        
        encoder.originalWidth = CVPixelBufferGetWidth(pixelBuffer)
        encoder.originalHeight = CVPixelBufferGetHeight(pixelBuffer)
        encoder.orientation = orientation
        encoder.quality = resolution
        
        guard let imageBuffer: CVPixelBuffer = fixOrientation(with: orientation, in: pixelBuffer) else { return }
        
        encoder.encodeImageBuffer(
            imageBuffer,
            presentationTimeStamp: sampleBuffer.presentationTimeStamp,
            duration: sampleBuffer.duration
        )
    }
}

extension HTMLStreamManager: JPEGEncoderDelegate {
    func jpegSampleOutput(video sampleBuffer: CMSampleBuffer) {
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
        let length = CMBlockBufferGetDataLength(blockBuffer)
        let bytes = UnsafeMutablePointer<Int16>.allocate(capacity: length)
        defer { bytes.deallocate() }

        guard CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: bytes) == kCMBlockBufferNoErr else { return }
        let data = Data(bytes: bytes, count: length)
//        try! data.write(to: .LastScreenshotFile)
        httpServer?.send(data) 
    }
}

extension HTMLStreamManager {
    private func fixOrientation(with orientation: CGImagePropertyOrientation, in pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        if orientation != .up { 
            var newPixelBuffer: CVPixelBuffer?
            let error = CVPixelBufferCreate(kCFAllocatorDefault,
                                            CVPixelBufferGetHeight(pixelBuffer),
                                            CVPixelBufferGetWidth(pixelBuffer),
                                            CVPixelBufferGetPixelFormatType(pixelBuffer),
                                            nil,
                                            &newPixelBuffer)
            guard error == kCVReturnSuccess, let buffer = newPixelBuffer else {
                return nil
            }
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(orientation.fixedOrientation)
            ciContext.render(ciImage, to: buffer)
            return buffer
        } else {
            return pixelBuffer
        }
    }
}
