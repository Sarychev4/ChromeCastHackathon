import Foundation
import VideoToolbox

protocol VTSessionPropertyKey {
    var CFString: CFString { get }
}

enum VTCompressionSessionPropertyKey: VTSessionPropertyKey {
    // Bitstream Configuration
    case depth
    case profileLevel
    case H264EntropyMode

    // Buffers
    case numberOfPendingFrames
    case pixelBufferPoolIsShared
    case videoEncoderPixelBufferAttributes

    // Clean Aperture and Pixel Aspect Ratio
    case aspectRatio16x9
    case cleanAperture
    case fieldCount
    case fieldDetail
    case pixelAspectRatio
    case progressiveScan

    // Color
    case colorPrimaries
    case transferFunction
    case YCbCrMatrix
    case ICCProfile

    // Expected Values
    case expectedDuration
    case expectedFrameRate
    case sourceFrameCount

    // Frame Dependency
    case allowFrameReordering
    case allowTemporalCompression
    case maxKeyFrameInterval
    case maxKeyFrameIntervalDuration

#if os(macOS)
    // Hardware Acceleration
    case usingHardwareAcceleratedVideoEncoder
    case requireHardwareAcceleratedVideoEncoder
    case enableHardwareAcceleratedVideoEncoder
#endif

    // Multipass Storage
    case multiPassStorage

    // Per-Frame Configuration
    case forceKeyFrame

    // Precompression Processing
    case pixelTransferProperties

    // Rate Control
    case averageBitRate
    case dataRateLimits
    case moreFramesAfterEnd
    case moreFramesBeforeStart
    case quality

    // Runtime Restriction
    case realTime
    case maxH264SliceBytes
    case maxFrameDelayCount

    // Others
    case encoderUsage

    var CFString: CFString {
        switch self {
        case .depth:
            return kVTCompressionPropertyKey_Depth
        case .profileLevel:
            return kVTCompressionPropertyKey_ProfileLevel
        case .H264EntropyMode:
            return kVTCompressionPropertyKey_H264EntropyMode
        case .numberOfPendingFrames:
            return kVTCompressionPropertyKey_NumberOfPendingFrames
        case .pixelBufferPoolIsShared:
            return kVTCompressionPropertyKey_PixelBufferPoolIsShared
        case .videoEncoderPixelBufferAttributes:
            return kVTCompressionPropertyKey_VideoEncoderPixelBufferAttributes
        case .aspectRatio16x9:
            return kVTCompressionPropertyKey_AspectRatio16x9
        case .cleanAperture:
            return kVTCompressionPropertyKey_CleanAperture
        case .fieldCount:
            return kVTCompressionPropertyKey_FieldCount
        case .fieldDetail:
            return kVTCompressionPropertyKey_FieldDetail
        case .pixelAspectRatio:
            return kVTCompressionPropertyKey_PixelAspectRatio
        case .progressiveScan:
            return kVTCompressionPropertyKey_ProgressiveScan
        case .colorPrimaries:
            return kVTCompressionPropertyKey_ColorPrimaries
        case .transferFunction:
            return kVTCompressionPropertyKey_TransferFunction
        case .YCbCrMatrix:
            return kVTCompressionPropertyKey_YCbCrMatrix
        case .ICCProfile:
            return kVTCompressionPropertyKey_ICCProfile
        case .expectedDuration:
            return kVTCompressionPropertyKey_ExpectedDuration
        case .expectedFrameRate:
            return kVTCompressionPropertyKey_ExpectedFrameRate
        case .sourceFrameCount:
            return kVTCompressionPropertyKey_SourceFrameCount
        case .allowFrameReordering:
            return kVTCompressionPropertyKey_AllowFrameReordering
        case .allowTemporalCompression:
            return kVTCompressionPropertyKey_AllowTemporalCompression
        case .maxKeyFrameInterval:
            return kVTCompressionPropertyKey_MaxKeyFrameInterval
        case .maxKeyFrameIntervalDuration:
            return kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration
        case .multiPassStorage:
            return kVTCompressionPropertyKey_MultiPassStorage
        case .forceKeyFrame:
            return kVTEncodeFrameOptionKey_ForceKeyFrame
        case .pixelTransferProperties:
            return kVTCompressionPropertyKey_PixelTransferProperties
        case .averageBitRate:
            return kVTCompressionPropertyKey_AverageBitRate
        case .dataRateLimits:
            return kVTCompressionPropertyKey_DataRateLimits
        case .moreFramesAfterEnd:
            return kVTCompressionPropertyKey_MoreFramesAfterEnd
        case .moreFramesBeforeStart:
            return kVTCompressionPropertyKey_MoreFramesBeforeStart
        case .quality:
            return kVTCompressionPropertyKey_Quality
        case .realTime:
            return kVTCompressionPropertyKey_RealTime
        case .maxH264SliceBytes:
            return kVTCompressionPropertyKey_MaxH264SliceBytes
        case .maxFrameDelayCount:
            return kVTCompressionPropertyKey_MaxFrameDelayCount
        case .encoderUsage:
            return "EncoderUsage" as CFString
        }
    }
}

extension VTCompressionSession {
    func setProperty(_ key: VTCompressionSessionPropertyKey, value: CFTypeRef?) -> OSStatus {
        VTSessionSetProperty(self, key: key.CFString, value: value)
    }

    public func setProperties(_ propertyDictionary: [NSString: NSObject]) -> OSStatus {
        VTSessionSetProperties(self, propertyDictionary: propertyDictionary as CFDictionary)
    }

    public func prepareToEncodeFrame() -> OSStatus {
        VTCompressionSessionPrepareToEncodeFrames(self)
    }

    public func invalidate() {
        VTCompressionSessionInvalidate(self)
    }

    func copySupportedPropertyDictionary() -> [AnyHashable: Any] {
        var support: CFDictionary?
        guard VTSessionCopySupportedPropertyDictionary(self, supportedPropertyDictionaryOut: &support) == noErr else {
            return [:]
        }
        guard let result = support as? [AnyHashable: Any] else {
            return [:]
        }
        return result
    }
}
