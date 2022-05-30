//
//  SampleHandler.swift
//  MirroringExtension
//
//  Created by Vital on 19.04.22.
//

import ReplayKit
import RealmSwift

class SampleHandler: RPBroadcastSampleHandler {
    private var htmlStream: HTMLStreamManager?
    private var streamInfoNotificationsToken: NotificationToken?
    private var resolution: ResolutionType = .low
    private var orientation: CGImagePropertyOrientation = .up
    private var isAutoRotate: Bool = true
    private var isSoundOn: Bool = true 
    private var streamConfiguration: StreamConfiguration! { StreamConfiguration.current }

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        print(">>> broadcast Started")
         
        resolution = streamConfiguration.resolutionType
        isAutoRotate = streamConfiguration.isAutoRotate
        isSoundOn = streamConfiguration.isSoundOn
        
        observeStreamInfoProperties()
        
//        guard streamConfiguration.deviceIp.isEmpty == false else { return }
        setupHTMLStream()
        
        try? streamConfiguration.realm?.write {
            streamConfiguration.event = StreamEvent.broadcastStarted.rawValue
            print(">>> broadcast \(streamConfiguration.event)")
        }
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            guard CMSampleBufferGetNumSamples(sampleBuffer) == 1,
                    CMSampleBufferIsValid(sampleBuffer),
                  CMSampleBufferDataIsReady(sampleBuffer)
            else { return }
                        
            orientation = isAutoRotate ? sampleBuffer.cgOrientation : .up
            
            if let htmlStream = htmlStream {
                htmlStream.encode(sampleBuffer, resolution: resolution, orientation: orientation)
            }
            break
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError(">>> Unknown type of sample buffer")
        }
    }
    
    override func broadcastFinished() {
        try? streamConfiguration.realm?.write {
            streamConfiguration.event = StreamEvent.broadcastFinished.rawValue
        }
    }
    
    override func broadcastPaused() { }
    
    override func broadcastResumed() { }
    
}

extension SampleHandler {
    
    private func setupHTMLStream() {
        let jpegEncoder = JPEGEncoder()
        htmlStream = HTMLStreamManager(encoder: jpegEncoder)
    }
    
    private func observeStreamInfoProperties() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.streamInfoNotificationsToken = self.streamConfiguration.observe { [weak self] (change) in
                guard let self = self else { return }
                switch change {
                case .change(_, let properties):
                    for property in properties {
                        if property.name == #keyPath(StreamConfiguration.isAutoRotate), let newValue = property.newValue as? Bool {
                            self.isAutoRotate = newValue
                        }
                        
                        if property.name == #keyPath(StreamConfiguration.resolutionType), let newValueInt = property.newValue as? Int, let newValue = ResolutionType(rawValue: newValueInt) {
                            self.resolution = newValue
                        }
                        
                        if property.name == #keyPath(StreamConfiguration.isSoundOn), let newValue = property.newValue as? Bool {
                            self.isSoundOn = newValue
                        }
                    }
                case .deleted: break
                case .error(_): break
                }
            }
        }
    }
}

