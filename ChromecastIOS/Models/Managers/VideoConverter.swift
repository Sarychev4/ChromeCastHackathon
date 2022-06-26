//
//  VideoConverter.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 19.05.2022.
//

import Foundation
import NextLevelSessionExporter
import Photos
import ffmpegkit

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
//        if let urlAsset = asset as? AVURLAsset {
//            let assetDuration = Float(CMTimeGetSeconds(urlAsset.duration))
//            let input = urlAsset.url.absoluteString
//            let output = fileURL.absoluteString
//            let command = "-re -i \(input) -map 0:0 -map 0:1 -vcodec copy -c:a copy -f mp4 -movflags faststart+frag_keyframe+separate_moof+omit_tfhd_offset+empty_moov \(output)"
////            let command = "-re -i \(input) -sc_threshold 0 -b_strategy 0 -use_timeline 1 -single_file 1 -use_template 1 -adaptation_sets 'id=0,streams=v id=1,streams=a' -f dash \(fileURL.deletingLastPathComponent())dash.mpd"
////            -re -i .\video-h264.mkv -map 0 -map 0 -c:a aac -c:v libx264 -b:v:0 800k -b:v:1 300k -s:v:1 320x170 -profile:v:1 baseline -profile:v:0 main -bf 1 -keyint_min 120 -g 120 -sc_threshold 0 -b_strategy 0 -ar:a:1 22050 -use_timeline 1 -single_file 1 -use_template 1 -window_size 5 -adaptation_sets "id=0,streams=v id=1,streams=a" -f dash out.mpd
//            
//            print(">>>> output mp4: \(output)")
//            FFmpegKit.executeAsync(command) { [weak self] session in
//                guard let self = self, let state = session?.getState() else { return }
//                print(">>>> session: \(String(describing: session?.getState().rawValue))")
//                
//                switch state {
//                case .created, .running:
//                    break
//                case .failed:
//                    onComplete(false)
//                case .completed:
//                    onComplete(true)
//                @unknown default:
//                    break
//                }
//            } withLogCallback: { log in
//                print(">>> ffmpeg: \(log?.getMessage() ?? "")")
//            } withStatisticsCallback: { statistics in
//                guard let statistics = statistics else { return }
//                let timeInMilliseconds = Float(statistics.getTime())
//                print(">>> ffmpeg progress: \(statistics.getTime())")
//                if timeInMilliseconds > 0 {
//                    let percentage = timeInMilliseconds/(assetDuration*1000)
//                    print(">>> ffmpeg percentage: \(percentage)")
//                    onProgress(min(percentage, 1))
//                }
//            }
//            return
//        }

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
    
    func getUrlFromPHAsset(asset: PHAsset, callBack: @escaping (_ url: URL?) -> Void) {
        asset.requestContentEditingInput(with: PHContentEditingInputRequestOptions(), completionHandler: { [weak self]  contentEditingInput, dictInfo in
            guard let strURL = (contentEditingInput!.audiovisualAsset as? AVURLAsset)?.url.absoluteString  else { return }
            print("VIDEO URL: \(strURL)")
            callBack(URL.init(string: strURL))
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
