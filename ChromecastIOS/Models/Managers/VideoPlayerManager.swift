//
//  VideoPlayerManager.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 20.05.2022.
//

import Foundation
//import Player
import Photos
import RealmSwift
import NextLevelSessionExporter
import MobileCoreServices
import GoogleCast

class VideoPlayerManager: NSObject {
    
    enum State {
        case none
        case iCloudDownloading(_ progress: Double)
        case convertingToMP4(_ progress: Float)
        case readyForTV
        case playing
        case paused
        case cancelled
        func isSameAs(_ type: Self) -> Bool {
              switch self {
              case .none: if case .none = type { return true }
              case .iCloudDownloading(_): if case .iCloudDownloading = type { return false }
              case .convertingToMP4(_): if case .convertingToMP4 = type { return true }
              case .readyForTV: if case .readyForTV = type { return true }
              case .playing: if case .playing = type { return true }
              case .paused: if case .paused = type { return true }
              case .cancelled: if case .cancelled = type { return true }
              }
              return false
           }
    }
    
    static let shared = VideoPlayerManager()
    
    var assetExportSession = VideoConverter()
    var stateObserver: ((_ state: VideoPlayerManager.State) -> ())?
    
    var imageManager: PHCachingImageManager!
    var asset: PHAsset?
    var convertedVideoFileURL: URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let videoFileURL = documentsDirectory?.appendingPathComponent("videoForCasting.mp4")
        return videoFileURL
    }
    
    private(set) var state: VideoPlayerManager.State = .none {
        didSet {
            if oldValue.isSameAs(state) == false || state.isSameAs(.playing) {
                stateObserver?(state)
            }
        }
    }
    
    private var iCloudRequestId: PHImageRequestID?
    
    //MARK: - Actions
    
    func prepareAssetForCastToTV(_ asset: PHAsset) {
        guard let videoFileURL = convertedVideoFileURL else { return }
        self.asset = asset
        if asset.localIdentifier == UserDefaults.standard.lastCompressedAssetId, FileManager.default.fileExists(atPath: videoFileURL.path) {
            state = .readyForTV
            return
        }
        downloadFromiCloud()
    }
    
    func cancelPreparing() {
        if let iCloudRequestId = iCloudRequestId {
            imageManager.cancelImageRequest(iCloudRequestId)
        }
        print(">>>> cancel prepare \(iCloudRequestId)")
        assetExportSession.cancelExport()
        state = .cancelled
    }
    
    func stop() {
        cancelPreparing()
        state = .none
    }
    
    private func downloadFromiCloud() {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.version = .original
        options.progressHandler = { (progress, error, data, info) in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.state = .iCloudDownloading(progress)
            }
        }
        
        if let iCloudRequestId = iCloudRequestId {
            imageManager.cancelImageRequest(iCloudRequestId)
        }
        
        // Делаю запрос на видео из галереи и если оно не скачано - скачиваю
        iCloudRequestId = imageManager.requestAVAsset(forVideo: self.asset!, options: options) { [weak self] (avasset, audiomix, info) in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard let avasset = avasset else {
                    self.state = .none
                    return
                } 
                self.convertVideoToMP4(avasset)
            }
        }
    }
    
    // onComplete: Closure?
    func convertVideoToMP4(_ avasset: AVAsset) {
        guard let videoFileURL = convertedVideoFileURL else { return }
        let quality = Settings.current.videosResolution
        
        stateObserver?(.convertingToMP4(0))
        
        if FileManager.default.fileExists(atPath: videoFileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: videoFileURL.path)
                print("Removed old video")
            } catch let removeError{
                print("couldn't remove file at path", removeError)
            }
        }
        
        assetExportSession.exportAsset(asset: avasset, quality: quality, toFileURL: videoFileURL, onProgress: { [weak self] progress in
            guard let self = self else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard self.state.isSameAs(.cancelled) == false else { return }
                self.stateObserver?(.convertingToMP4(progress))
            }
        }, onComplete: { [weak self] isSuccess in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if isSuccess {
                    UserDefaults.standard.lastCompressedAssetId = self.asset?.localIdentifier
                    self.state = .readyForTV
                } else {
                    self.state = .none
                }
            }
        })
    }
    
    func startObserveVideoState() {
        ChromeCastService.shared.observePlayerState { state in
            switch state {
            case 1:
                self.state = .none
            case 2:
                self.state = .playing
            case 3:
                self.state = .paused
            default:
                print("")
            }
        }
    }
    
}
