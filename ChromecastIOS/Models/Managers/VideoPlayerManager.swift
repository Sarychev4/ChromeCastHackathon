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

class VideoPlayerManager: NSObject {
    
    enum State {
        case convertingToMP4(_ progress: Float)
    }
    
    static let shared = VideoPlayerManager()
    var stateObserver: ((_ state: VideoPlayerManager.State) -> ())?
    var assetExportSession = VideoConverter()
    
    func convertVideoToMP4(_ avasset: AVAsset, onComplete: Closure?) {
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
                    onComplete?()
                } else {
                    
                }
            }
        })
    }
}
