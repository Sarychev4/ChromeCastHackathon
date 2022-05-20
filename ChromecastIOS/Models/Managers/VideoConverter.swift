//
//  VideoConverter.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 19.05.2022.
//

import Foundation
import NextLevelSessionExporter
import Photos


class VideoConverter: NSObject {
    private var exporter: NextLevelSessionExporter?
    private var avExporter: AVAssetExportSession?
    private var progressBlock: ((Float) ->())?
    private var completeBlock: ClosureBool?
    
    func exportAsset(
        asset: AVAsset,
        quality: ResolutionType,
        toFileURL fileURL: URL,
        onProgress: @escaping (Float) -> (),
        onComplete: @escaping ClosureBool
    ) {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            onComplete(false)
            return
        }
        
        let size = videoTrack.naturalSize
        
        exporter = NextLevelSessionExporter(withAsset: asset)
        exporter?.outputFileType = AVFileType.mp4
        exporter?.outputURL = fileURL
        exporter?.optimizeForNetworkUse = true
        
        var bitrate = CGFloat(6000000)
        switch quality {
        case .low:
            bitrate = min(size.width * size.height / CGFloat(3), 500000)
        case .medium:
            bitrate = min(size.width * size.height / CGFloat(2), 2500000)
        case .high:
            bitrate = min(size.width * size.height, 5000000)
        }
        
        let compressionDict: [String: Any] = [
            AVVideoAverageBitRateKey: NSNumber(integerLiteral: Int(bitrate)),
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel as String,
        ]
        
        let maxSize = CGSize(width: 1920, height: 1080)
        
        var scale: CGFloat = 1
        if size.width > maxSize.width {
            scale = maxSize.width / size.width
        } else if size.height > maxSize.height {
            scale = maxSize.height / size.height
        }
        let newWidth = size.width * scale
        let newHeight = size.height * scale
        let width = NSNumber(integerLiteral: Int(newWidth))
        let height = NSNumber(integerLiteral: Int(newHeight))
        
        exporter?.videoOutputConfiguration = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoScalingModeKey: AVVideoScalingModeResize,
            AVVideoCompressionPropertiesKey: compressionDict
        ]
        exporter?.audioOutputConfiguration = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderBitRateKey: NSNumber(integerLiteral: 128000),
            AVNumberOfChannelsKey: NSNumber(integerLiteral: 2),
            AVSampleRateKey: NSNumber(value: Float(44100))
        ]
        
        exporter?.export(progressHandler: { (progress) in
            onProgress(progress)
        }, completionHandler: { result in
            switch result {
            case .success(let status):
                switch status {
                case .failed:
                    onComplete(false)
                case .cancelled:
                    onComplete(false)
                case .completed:
                    onComplete(true)
                default: break
                }
                break
            case .failure(let error):
                print("NextLevelSessionExporter, failed to export \(error)")
                onComplete(false)
                break
            }
            
        })
        
    }
    
    func cancelExport() {
        exporter?.cancelExport()
        avExporter?.cancelExport()
    }
    
    func ffmpegConvert(inputFileUrl: URL, outputFileUrl: URL, inputDuration: Float) {
        let input = inputFileUrl.absoluteString
        let output = outputFileUrl.absoluteString
        let command = "-i \(input) -c:v h264 -vf  scale=480:360:force_original_aspect_ratio=decrease,pad=480:360:(ow-iw)/2:(oh-ih)/2,setsar=1 -c:a copy \(output)"
        print(">>> ffmpeg commang: \(command)")
    }
}
