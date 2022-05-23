//
//  JPEGEncoder.swift
//  ScreenMirroring
//
//  Created by Vital on 12.11.21.
//

import Foundation
import AVFoundation
import CoreFoundation
import VideoToolbox
import UIKit
import CoreImage
//import ffmpegkit

public enum ScalingMode: String {
    /*
     kVTScalingMode_Normal
     The full width and height of the source image buffer is stretched to the full width and height of the destination image buffer.
     kVTScalingMode_CropSourceToCleanAperture
     The source image buffer's clean aperture is scaled to the destination clean aperture.
     kVTScalingMode_Letterbox
     The source image buffer's clean aperture is scaled to a rectangle fitted inside the destination clean aperture that preserves the source picture aspect ratio.
     kVTScalingMode_Trim
     The source image buffer's clean aperture is scaled to a rectangle that completely fills the destination clean aperture and preserves the source picture aspect ratio.
     */
    case normal = "Normal"
    case letterbox = "Letterbox"
    case cropSourceToCleanAperture = "CropSourceToCleanAperture"
    case trim = "Trim"
}


public protocol JPEGEncoderDelegate: AnyObject {
    func jpegSampleOutput(video sampleBuffer: CMSampleBuffer)
}

// MARK: -
public final class JPEGEncoder {
    public static let defaultWidth: Int32 = 0
    public static let defaultHeight: Int32 = 0
    public static let defaultScalingMode: ScalingMode = .normal
     
    static let defaultAttributes: [NSString: AnyObject] = [
        kCVPixelBufferIOSurfacePropertiesKey: [:] as AnyObject,
        kCVPixelBufferOpenGLESCompatibilityKey: kCFBooleanTrue
    ]
    
    var originalWidth: Int = 0
    var originalHeight: Int = 0
    
    var scalingMode: ScalingMode = JPEGEncoder.defaultScalingMode {
        didSet {
            guard scalingMode != oldValue else { return }
            invalidateSession = true
        }
    }

    var width: Int32 = JPEGEncoder.defaultWidth {
        didSet {
            guard width != oldValue else { return }
            print(">>> change jpeg encoder width to: \(width)")
            invalidateSession = true
        }
    }
    var height: Int32 = JPEGEncoder.defaultHeight {
        didSet {
            guard height != oldValue else { return }
            print(">>> change jpeg encoder height to: \(height)")
            invalidateSession = true
        }
    }
    var profileLevel: String = kVTProfileLevel_H264_Baseline_3_1 as String {
        didSet {
            guard profileLevel != oldValue else { return }
            invalidateSession = true
        }
    }
    var quality: ResolutionType = .low {
        didSet {
            guard quality != oldValue || width == 0 else { return }
            width = Int32(CGFloat(originalWidth) * quality.scaleSize)
            height = Int32(CGFloat(originalHeight) * quality.scaleSize)
            invalidateSession = true
        }
    }
    var orientation: CGImagePropertyOrientation = .up {
        didSet {
            guard orientation != oldValue else { return }
            let max = max(width, height)
            let min = min(width, height)
            if orientation != .up && width < height {
                width = Int32(max)
                height = Int32(min)
            } else if width > height {
                width = Int32(min)
                height = Int32(max)
            }
            invalidateSession = true
        }
        
    }
    var maxKeyFrameIntervalDuration: Double = 1.0 {
        didSet {
            guard maxKeyFrameIntervalDuration != oldValue else { return }
            invalidateSession = true
        }
    }
    var expectedFPS: Float64 = 60 {
        didSet {
            guard expectedFPS != oldValue else { return }
            setProperty(kVTCompressionPropertyKey_ExpectedFrameRate, NSNumber(value: expectedFPS))
        }
    }
    var formatDescription: CMFormatDescription? {
        didSet {
            guard !CMFormatDescriptionEqual(formatDescription, otherFormatDescription: oldValue) else { return }
        }
    }
    weak var delegate: JPEGEncoderDelegate?

    private(set) var status: OSStatus = noErr
    private var attributes: [NSString: AnyObject] {
        var attributes: [NSString: AnyObject] = JPEGEncoder.defaultAttributes
        attributes[kCVPixelBufferWidthKey] = NSNumber(value: width)
        attributes[kCVPixelBufferHeightKey] = NSNumber(value: height)
        return attributes
    }
    private var invalidateSession = true

    private var frameCount = 0
    // @see: https://developer.apple.com/library/mac/releasenotes/General/APIDiffsMacOSX10_8/VideoToolbox.html
    private var properties: [NSString: NSObject] {
        var properties: [NSString: NSObject] = [
            kVTCompressionPropertyKey_Quality: NSNumber(value: quality.encoder),
            kVTCompressionPropertyKey_RealTime: kCFBooleanTrue,
        ]
        if #available(iOS 14, *) {
            properties[kVTCompressionPropertyKey_PrioritizeEncodingSpeedOverQuality] = kCFBooleanTrue
        }
        return properties
    }

    //MARK: -
    //MARK: Callback HERE <<<<<<<<<<<<<<<<<<<<<<<<<<
    private var callback: VTCompressionOutputCallback = {(outputCallbackRefCon: UnsafeMutableRawPointer?, _: UnsafeMutableRawPointer?, status: OSStatus, infoFlags: VTEncodeInfoFlags, sampleBuffer: CMSampleBuffer?) in
        guard
            let refcon: UnsafeMutableRawPointer = outputCallbackRefCon,
            let sampleBuffer: CMSampleBuffer = sampleBuffer, status == noErr else {
                if status == kVTParameterErr {
                    // on iphone 11 with size=1792x827 this occurs
                    print(">>> encoding failed with kVTParameterErr. Perhaps the width x height is too big for the encoder setup?")
                }
            return
        }
        let encoder: JPEGEncoder = Unmanaged<JPEGEncoder>.fromOpaque(refcon).takeUnretainedValue()
        encoder.formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
        encoder.delegate?.jpegSampleOutput(video: sampleBuffer)
    }
    //MARK: -

    private var _session: VTCompressionSession?
    private var session: VTCompressionSession? {
        get {
            if _session == nil {
                frameCount = 0;
                guard VTCompressionSessionCreate(
                    allocator: kCFAllocatorDefault,
                    width: width,
                    height: height,
                    codecType: kCMVideoCodecType_JPEG,
                    encoderSpecification: nil,
                    imageBufferAttributes: attributes as CFDictionary?,
                    compressedDataAllocator: nil,
                    outputCallback: callback,
                    refcon: Unmanaged.passUnretained(self).toOpaque(),
                    compressionSessionOut: &_session
                    ) == noErr, let session = _session else {
                    print(">>> create a VTCompressionSessionCreate")
                    return nil
                }
                invalidateSession = false
                status = session.setProperties(properties)
                status = session.prepareToEncodeFrame()
                guard status == noErr else {
                    print(">>> setup failed VTCompressionSessionPrepareToEncodeFrames. Size = \(width)x\(height)")
                    return nil
                }
            }
            return _session
        }
        set {
            _session?.invalidate()
            _session = newValue
        }
    }

    init() {
        
    }

    func encodeImageBuffer(_ imageBuffer: CVImageBuffer, presentationTimeStamp: CMTime, duration: CMTime) {
        if invalidateSession {
            session = nil
        }
        guard let session: VTCompressionSession = session else {
            print(">>>> invalidateSession!!")
            return
        }
        var flags: VTEncodeInfoFlags = []
        
        VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: imageBuffer,
            presentationTimeStamp: presentationTimeStamp,
            duration: duration,
            frameProperties: nil,
            sourceFrameRefcon: nil,
            infoFlagsOut: &flags
        )
    }

    private func setProperty(_ key: CFString, _ value: CFTypeRef?) {
        guard let session: VTCompressionSession = self._session else {
            return
        }
        self.status = VTSessionSetProperty(
            session,
            key: key,
            value: value
        )
    } 
}

extension JPEGEncoder {
    // MARK: Running 
    public func stopRunning() {
        self.session = nil
        self.formatDescription = nil
    }
}
