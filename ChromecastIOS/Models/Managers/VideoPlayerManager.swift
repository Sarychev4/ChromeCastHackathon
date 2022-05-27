//
//  VideoPlayerManager.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 20.05.2022.
//

import Foundation
import Player
import Photos
import RealmSwift
import NextLevelSessionExporter
import MobileCoreServices
import GoogleCast
import Player

class VideoPlayerManager: NSObject {
    
    enum State {
        case none
        case iCloudDownloading(_ progress: Double)
        case convertingToMP4(_ progress: Float)
        case readyForTV
        case playing
        case paused
        func isSameAs(_ type: Self) -> Bool {
              switch self {
              case .none: if case .none = type { return true }
              case .iCloudDownloading(_): if case .iCloudDownloading = type { return false }
              case .convertingToMP4(_): if case .convertingToMP4 = type { return true }
              case .readyForTV: if case .readyForTV = type { return true }
              case .playing: if case .playing = type { return true }
              case .paused: if case .paused = type { return true }
              }
              return false
           }
    }
    
    static let shared = VideoPlayerManager()
    var videoProgressTimer: Timer?
    var currentTime: TimeInterval = 0
    var assetExportSession = VideoConverter()
    var stateObserver: ((_ state: VideoPlayerManager.State) -> ())?
    
    var imageManager: PHCachingImageManager!
    var asset: PHAsset?
    
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
        self.asset = asset
        if asset.localIdentifier == UserDefaults.standard.lastCompressedAssetId {
            state = .readyForTV
            return
        }
        downloadFromiCloud()
    }
    
    func cancelPreparing() {
        if let iCloudRequestId = iCloudRequestId {
            imageManager.cancelImageRequest(iCloudRequestId)
        }
        assetExportSession.cancelExport()
        state = .none
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
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let videoFileURL = documentsDirectory.appendingPathComponent("videoForCasting.mp4")
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
    
    func startObserveVideoProgress() {
        var dropRequestCount = 0
        stopVideoProgressTimer()
        videoProgressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
            guard let self = self else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
                guard let currentTimeOnTV = remoteMediaClient?.approximateStreamPosition() else { return }
                
//                    print("currentTimeOnTV: \(currentTimeOnTV), phone: \(self.currentTime)")
                    if self.currentTime == 0 && currentTimeOnTV > TimeInterval(1), dropRequestCount == 0 {
                        dropRequestCount += 1
                        // Это кейс когда переключили с одного видео на другой, а инфа устаревшая про предыдущее видео все еще доходит
                        return
                    }

                    let videoDuration = Int(self.asset?.duration ?? 0)
                    
                    if currentTimeOnTV > 0 {
                        
                        if currentTimeOnTV != self.currentTime {
                            self.currentTime = currentTimeOnTV
                            self.state = .playing
                            print(">>>Playing")
                        } else {
                            // НА FireTV когда заканчивается видео - оно висит на последней секунде, будто на паузе
                            //На Року оно закрывается. Поэтому надо обрабатывать все кейсы
                            // Тут проверяем что если до конца осталось меньше секунды, значит видео закончилось, если больше значит видео зависло на паузе
                            if abs(TimeInterval(videoDuration) - currentTimeOnTV) < 0.9 {
                                self.state = .none
                            } else {
                                self.state = .paused
                            }
                        }
                    } else if self.currentTime > 0 {
                        print("currentTime: \(currentTimeOnTV)")
                        // Кейс когда предыдущий запрос был не 0, а следующий 0 это когда видео закончилось.
                        self.state = .none
                    }
                }
        })
    }
    
    fileprivate func stopVideoProgressTimer() {
        videoProgressTimer?.invalidate()
        videoProgressTimer = nil
    }
    
}
