//
//  SampleHandler.swift
//  MirroringExtension
//
//  Created by Vital on 19.04.22.
//

import ReplayKit
import RealmSwift
import WebRTC
import WebRTCiOSSDK


class SampleHandler: RPBroadcastSampleHandler, AntMediaClientDelegate {
    func clientDidConnect(_ client: WebRTCiOSSDK.AntMediaClient) {
        
    }
    
    func clientDidDisconnect(_ message: String) {
        
    }
    
    func clientHasError(_ message: String) {
        let userInfo = [NSLocalizedFailureReasonErrorKey: message]
       
        finishBroadcastWithError(NSError(domain: "ScreenShare", code: -99, userInfo: userInfo));
    }
    
    func remoteStreamStarted(streamId: String) {
        
    }
    
    func remoteStreamRemoved(streamId: String) {
        
    }
    
    func localStreamStarted(streamId: String) {
        
    }
    
    func playStarted(streamId: String) {
        
    }
    
    func playFinished(streamId: String) {
        
    }
    
    func publishStarted(streamId: String) {
        NSLog("Publish has started");
    }
    
    func publishFinished(streamId: String) {
        NSLog("Publish has finished");
    }
    
    func disconnected(streamId: String) {
        
    }
    
    func audioSessionDidStartPlayOrRecord(streamId: String) {
        
    }
    
    func dataReceivedFromDataChannel(streamId: String, data: Data, binary: Bool) {
        
    }
    
    func streamInformation(streamInfo: [WebRTCiOSSDK.StreamInformation]) {
        
    }
    
     
    private var streamInfoNotificationsToken: NotificationToken?
    private var resolution: ResolutionType = .low
    private var orientation: CGImagePropertyOrientation = .up
    private var isAutoRotate: Bool = true
    private var isSoundOn: Bool = true 
    private var streamConfiguration: StreamConfiguration! { StreamConfiguration.current }
    
    let client: AntMediaClient = AntMediaClient.init()
    var videoEnabled: Bool = true;
    var audioEnabled: Bool = true;

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        print(">>> broadcast Started")
         
        resolution = streamConfiguration.resolutionType
        isAutoRotate = streamConfiguration.isAutoRotate
        isSoundOn = streamConfiguration.isSoundOn
        observeStreamInfoProperties()
        try? streamConfiguration.realm?.write {
            streamConfiguration.event = StreamEvent.broadcastStarted.rawValue
            print(">>> broadcast \(streamConfiguration.event)")
        }
        
        //AntMedia Part
        broadcastStartedAntMedia(withSetupInfo: setupInfo)
        
    }
    
    func broadcastStartedAntMedia(withSetupInfo setupInfo: [String : NSObject]?) {
        let sharedDefault = UserDefaults(suiteName: "group.chromecast.ios")!

        let streamId = "test"//sharedDefault.object(forKey: "streamId");
        let url = sharedDefault.object(forKey: "url");
        let token = sharedDefault.object(forKey: "token");
        
        let videoEnabledObject = sharedDefault.object(forKey:"videoEnabled") as! String;
        if videoEnabledObject == "false"
        {
            videoEnabled = false;
        }
        
        let audioEnabledObject = sharedDefault.object(forKey:"audioEnabled") as! String;
        if audioEnabledObject == "false" {
            audioEnabled = false;
        }
        
        if ((streamId) == nil)
        {
            let userInfo = [NSLocalizedFailureReasonErrorKey: "StreamId is not specified. Please specify stream id in the container app"]
           
            finishBroadcastWithError(NSError(domain: "ScreenShare", code: -1, userInfo: userInfo));
        }
        else if ((url) == nil)
        {
            let userInfo = [NSLocalizedFailureReasonErrorKey: "URL is not specified. Please specify URL in the container app"]
            finishBroadcastWithError(NSError(domain: "ScreenShare", code: -2, userInfo: userInfo));
        }
        else {
            NSLog("----> streamId: %@ , websocket url: %@, videoEnabled: %d , audioEnabled: %d", streamId as! String, url as! String,
                  videoEnabled, audioEnabled);
            
            self.client.delegate = self
            self.client.setDebug(true)
            self.client.setOptions(url: url as! String, streamId: streamId as! String, token: token as? String ?? "", mode: AntMediaClientMode.join, enableDataChannel: true, captureScreenEnabled: true);
            self.client.setExternalAudio(externalAudioEnabled: true)
            self.client.initPeerConnection();
            self.client.start();
        }
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            if videoEnabled {
                self.client.deliverExternalVideo(sampleBuffer: sampleBuffer);
            }
            break
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            if audioEnabled {
                self.client.deliverExternalAudio(sampleBuffer: sampleBuffer);
            }
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

