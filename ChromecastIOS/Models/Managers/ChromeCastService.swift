//
//  ChromeCastService.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 05.05.2022.
//

import Foundation
import GoogleCast
import RealmSwift
import UIKit
import CSSystemInfoHelper
import AVFAudio
import Network
//import Indicate

class ChromeCastService: NSObject {
    //785537D5 - фотки не кастятся, экран не трансилруется с хромкаста, экран передается на сайт
    // 2C5BA44D - кастятся фотки, экран не трансилируется с хромкаста, экран передается на сайт
//    let kReceiverAppID = "2C5BA44D"//"2C5BA44D"//"785537D5"//temp vr 1!!!! // "785537D5"// "D7506266""2C5BA44D"
    let kDebugLoggingEnabled = true
    
    static let shared = ChromeCastService()
    
    var foundedDevices: [GCKDevice] = []
    var screenMirroringChannel: GCKCastChannel?
    var sessionManager: GCKSessionManager?
    var currentConnectedDeviceID: String?
    var connectFinished: ClosureBool?
    var isSessionResumed: Bool = false
    var outputVolumeObserve: NSKeyValueObservation?
    let audioSession = AVAudioSession.sharedInstance()
    
    private var notificationToken: NotificationToken!
    private var playerStateNotificationToken: NotificationToken?
    private var timeProgressTimer: Timer?
    private var nwPathMonitor: NWPathMonitor?
    private var isWifiConnected: Bool?
    private var isWiFiFound = false
    
    private override init(){
        
    }
    
    func initialize(kReceiverAppID: String) {
       
        print(">>>ChromeCast Service was initialized")
        clearAllDevices()
       // let criteria = GCKDiscoveryCriteria(applicationID: kReceiverAppID)
        
        //>>>>>
        let criteria = GCKDiscoveryCriteria(applicationID: kReceiverAppID)
        let initWithIds = Selector(("initWithApplicationIDs:"))
        if criteria.responds(to: initWithIds) {
            criteria.perform(initWithIds, with: NSOrderedSet(array: [kReceiverAppID, "785537D5"]))

        }
            
//        let options = GCKCastOptions(discoveryCriteria: criteria)
//        GCKCastContext.setSharedInstanceWith(options)
        
        //>>>>>>
        let options = GCKCastOptions(discoveryCriteria: criteria)
        let launchOptions = GCKLaunchOptions(relaunchIfRunning: true)
        launchOptions.androidReceiverCompatible = false
        options.launchOptions = launchOptions
        options.suspendSessionsWhenBackgrounded = false
        options.disableAnalyticsLogging = true
        options.disableDiscoveryAutostart = true
        options.stopReceiverApplicationWhenEndingSession = true;
        options.physicalVolumeButtonsWillControlDeviceVolume = true;
        options.startDiscoveryAfterFirstTapOnCastButton = false;
        GCKCastContext.setSharedInstanceWith(options)
        GCKLogger.sharedInstance().delegate = self
        let deviceScanner = GCKCastContext.sharedInstance().discoveryManager
        deviceScanner.add(self)
        deviceScanner.startDiscovery()
        
        self.sessionManager = GCKCastContext.sharedInstance().sessionManager
        
        self.sessionManager!.add(self)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            //            self.sessionManager?.endSessionAndStopCasting(true)
        }
        
        observeStreamConfiguration()
        listenVolumeButton()
        createPlayerObject()
    }
    
    func createPlayerObject() {
        let realm = try! Realm()
        let playerStates = realm.objects(PlayerState.self)
            if playerStates.isEmpty {
                let playerState = PlayerState()
                playerState.state = .idle
                let realm = try! Realm()
                try! realm.write {
                    realm.add(playerState)
                }
                print(">>> New Player State was added to the REALM")

            }
    }
    
    func clearAllDevices() {
        let realm = try! Realm()
        let deviceObjs = realm.objects(DeviceObject.self)
        try! realm.write({
            realm.delete(deviceObjs)
        })
    }
    
    func startDiscovery() {
        
        /*
         */
        
        observeWiFi()
        
        /*
         */
        
        let deviceScanner = GCKCastContext.sharedInstance().discoveryManager
        deviceScanner.add(self)
        deviceScanner.startDiscovery()
    }
    
    func listenVolumeButton() {
       do {
        try audioSession.setActive(true)
       } catch {
        print("some error")
       }
       audioSession.addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions.new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
      if keyPath == "outputVolume" {
          let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
          remoteMediaClient?.setStreamVolume(audioSession.outputVolume) 
      }
    }
    
    func pauseVideo() {
        let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
        remoteMediaClient?.pause()
    }
    
    func playVideo() {
        let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
        remoteMediaClient?.play()
    }
    
    func connect(to deviceID: String, onComplete: ClosureBool?) {
        let deviceScanner = GCKCastContext.sharedInstance().discoveryManager
        guard let device = deviceScanner.device(withUniqueID: deviceID) else { return }
        
        startNewSession(with: device)
        self.connectFinished = onComplete
        
    }
    
    private func observeWiFi() {
        guard nwPathMonitor == nil else { return }
        nwPathMonitor = NWPathMonitor()
        nwPathMonitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
//            CSSystemInfoHelper.shared.update()
            let isWifiConnected = path.usesInterfaceType(.wifi)
            guard self.isWifiConnected == nil || self.isWifiConnected != isWifiConnected else { return }
            self.isWifiConnected = isWifiConnected
            if isWifiConnected == false {
                self.showNoWiFiToast()
                //Не отправлять WiFi_lost если до этого не было WiFi_found
                if self.isWiFiFound {
                  
                }
//                if let connectableDevice = self.connectableDevice {
//                    self.disconnect(connectableDevice)
//                }
//                self.discoveryManager.clearDeviceList()
            } else {
                self.isWiFiFound = true
                
                self.startDiscovery()
            }
        }

        nwPathMonitor?.start(queue: .main)
    }
    
    private func showNoWiFiToast() {
//        guard let view = TopViewController?.view else { return }
//        let content = Indicate.Content(
//            title: .init(value: NSLocalizedString("NoWifiTitle", comment: ""), alignment: .natural),
//            attachment: .image(.init(value: UIImage(named: "IconWiFiRed")))
//        )
//        
//        let config = Indicate.Configuration(
//            duration: 10,
//            size: CGSize(width: 300, height: 75),
//            titleColor: .red,
//            backgroundColor: .white,
//            titleFont: .systemFont(ofSize: 18))
//            .with(tap: { controller in
//                controller.dismiss()
//            })
//        
//        let controller = Indicate.PresentationController(content: content, configuration: config)
//        controller.present(in: view)
    }
    
    func startNewSession(with device: GCKDevice){
        print(">>>Start new session with device \(device)")
        self.sessionManager!.startSession(with: device)
    }
    
    func endSession() {
        self.sessionManager!.endSession()
    }
    
    func displayImage(with url: URL) {
        let params = ["type": "image", "url": url.absoluteString]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: params, options: [])
            guard let convertedString = String(data: jsonData, encoding: String.Encoding.utf8) else {return}
            screenMirroringChannel?.sendTextMessage(convertedString, error: nil)
        } catch {
            print(error.localizedDescription)
            print(">>>\(error.localizedDescription)")
        }
    }
    
    func displayVideo(with url: URL, previewImage: URL? = nil) {
        let metadata = GCKMediaMetadata(metadataType: .movie)
        if let previewUrl = previewImage {
            metadata.addImage(GCKImage(url: previewUrl, width: 60, height: 60) )
        }
        let mediaInfoBuilder = GCKMediaInformationBuilder(contentURL: url)
        mediaInfoBuilder.contentType = "video/mp4" //mediaInfo.mimeType
        mediaInfoBuilder.streamType = GCKMediaStreamType.none
        mediaInfoBuilder.metadata = metadata
        let mediaInformation = mediaInfoBuilder.build()
        let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
        remoteMediaClient?.loadMedia(mediaInformation)
        remoteMediaClient?.add(self)
    }
    
    func showDefaultMediaVC() {
        GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = true
        let defaultMediaVC = GCKCastContext.sharedInstance().defaultExpandedMediaControlsViewController
        defaultMediaVC.view.allSubviews.forEach ({
            if $0.className == "GCKUICastButton" {
                $0.layer.opacity = 0
                $0.layer.isHidden = true
                $0.isUserInteractionEnabled = false
                let imageView = $0.subviews.first as? UIImageView
                imageView?.layer.isHidden = true
                imageView?.layer.opacity = 0
            }
        })
         
        GCKCastContext.sharedInstance().presentDefaultExpandedMediaControls()
    }
    
    private func startObserveVideoTimeProgress() {
        stopObserveVideoTimeProgress()
        timeProgressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] (timer) in
            guard let _ = self else { return }
            let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
            let value = remoteMediaClient?.approximateStreamPosition()
            print(">>>> slider time: \(String(describing: value))")
        })
    }
    
    private func stopObserveVideoTimeProgress() {
        timeProgressTimer?.invalidate()
        timeProgressTimer = nil
    }
    
    func stopWebApp() {
        let params = ["type": "stop"]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: params, options: [])
            guard let convertedString = String(data: jsonData, encoding: String.Encoding.utf8) else {return}
            screenMirroringChannel?.sendTextMessage(convertedString, error: nil)
        } catch {
            print(error.localizedDescription)
            print(">>>\(error.localizedDescription)")
        }
    }
    
    func displayStream(with url: URL) {
        print("diplay stream runned")
        let params = ["type": "stream", "url": url.absoluteString]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: params, options: [])
            guard let convertedString = String(data: jsonData, encoding: String.Encoding.utf8) else {return}
            screenMirroringChannel?.sendTextMessage(convertedString, error: nil)
        } catch {
            print(error.localizedDescription)
            print(">>>\(error.localizedDescription)")
        }
    }
    
    func observePlayerState(onComplete: @escaping ((Int) -> ())) {
        let realm = try! Realm()
        if let playerStateObj = realm.objects(PlayerState.self).first {
            playerStateNotificationToken = playerStateObj.observe { [weak self] changes in
                guard let _ = self else { return }
                switch changes {
                case .change(let object, let properties):
                    for property in properties {
                        if property.name == #keyPath(PlayerState.state) {
                            if let newVal = property.newValue as? Int {
                                onComplete(newVal)
                            }
                        }
                        
                    }
                case .error(let error):
                    print(">>> PlayerStateObj An error occurred: \(error)")
                    onComplete(0)
                case .deleted:
                    onComplete(0)
                    print(">>> PlayerStateObj was deleted.")
                }
            }
        }
    }
    
    private func observeStreamConfiguration() {
        notificationToken = StreamConfiguration.current.observe { (changes) in
            switch changes {
            case .error(_): break
            case .change(_, let properties):
                for property in properties {
                    if property.name == #keyPath(StreamConfiguration.event), let value = property.newValue as? String, let event = StreamEvent(rawValue: value) {
                        switch event {
                        case .broadcastStarted:
                            
                            
                            guard let deviceIP = CSSystemInfoHelper.ipAddress else { return }
                            guard let url = URL(string: "http://\(deviceIP):\(Port.htmlStreamPort.rawValue)/screenmirror") else { return }
                            
                            self.displayStream(with: url)
                            
                        case .broadcastFinished:
                            
                            self.stopWebApp()
                        }
                    }
                }
            case .deleted: break
            }
        }
    }
}

extension ChromeCastService: GCKRequestDelegate {
    
}

extension ChromeCastService: GCKRemoteMediaClientListener {
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        guard let mediaStatus = mediaStatus else { return }
//        if mediaStatus.playerState == .playing {
//            startObserveVideoTimeProgress()
//        } else {
//            stopObserveVideoTimeProgress()
//        }
        let realm = try! Realm()
        if let playerState = realm.objects(PlayerState.self).first {
            if playerState.state.rawValue != mediaStatus.playerState.rawValue {
                try! realm.write {
                    playerState.state = PlayerCurrentState(rawValue: mediaStatus.playerState.rawValue) ?? .unknown
                }
            }
           
        }
//        print(">>> remoteMediaClient time: \(mediaStatus.streamPosition), state: \(mediaStatus.playerState.rawValue))")
    }
}

extension ChromeCastService: GCKLoggerDelegate {
    func logMessage(_ message: String, at level: GCKLoggerLevel, fromFunction function: String, location: String) {
        if (kDebugLoggingEnabled) {
            print(">>>ChromeCast Logger: " + function + " - " + message)
        }
    }
}

//MARK: - DiscoveryManagerListener
extension ChromeCastService: GCKDiscoveryManagerListener {
    
    func didStartDiscovery(forDeviceCategory deviceCategory: String) {
        print(">>>ChromeCast: Discovery was started for category \(deviceCategory)")
    }
    
    func willUpdateDeviceList() {
        print(">>>ChromeCast: DiscoveryList will be updated in some way")
    }
    
    func didUpdateDeviceList() {
        print(">>>ChromeCast: DiscoveryList was updated in some way")
    }
    
    func didInsert(_ device: GCKDevice, at index: UInt) {
        let deviceObj = DeviceObject()
        deviceObj.deviceID = device.deviceID
        deviceObj.deviceUniqueID = device.uniqueID
        deviceObj.friendlyName = device.friendlyName ?? "No friendly name"
        deviceObj.modelName = device.modelName ?? "No model name"
        deviceObj.isConnected = false
        let realm = try! Realm()
        try! realm.write {
            realm.add(deviceObj, update: .all)
        }
        
        self.foundedDevices.append(device)
        print(">>>ChromeCast: Newly-discovered device \(device.friendlyName ?? "No friendly name") has been inserted into the list of devices.")
    }
    
    func didUpdate(_ device: GCKDevice, at index: UInt) {
        print(">>>ChromeCast: Previously-discovered device \(device.friendlyName ?? "No friendly name") has been updated.")
    }
    
    func didRemove(_ device: GCKDevice, at index: UInt) {
        let realm = try! Realm()
        guard let deviceObj = realm.object(ofType: DeviceObject.self, forPrimaryKey: device.deviceID) else { return }
        try! realm.write({
            realm.delete(deviceObj)
        })
        self.foundedDevices.remove(at: Int(index))
        
        print(">>>ChromeCast: Called when a previously-discovered device \(device.friendlyName ?? "No friendly name") has gone offline and has been removed from the list of devices.")
    }
    
    func didHaveDiscoveredDeviceWhenStartingDiscovery() {
        print(">>>ChromeCast: Some discovered devices already in the list before discovery was started")
    }
}

//MARK: - SessionManagerListener GCKSession
extension ChromeCastService: GCKSessionManagerListener {
    
    func sessionManager(_ sessionManager: GCKSessionManager, willStart session: GCKSession) {
        print(">>>ChromeCast: Session is about to be started")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, willStart session: GCKCastSession) {
        print(">>>ChromeCast: Cast session is about to be started")
    }
    
    /*
     */
    
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        print(">>>ChromeCast: Session has been successfully started")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
        print(">>>ChromeCast: Cast session has been successfully started")
        self.screenMirroringChannel = GCKCastChannel(namespace:"urn:x-cast:com.mirroring.screen.sharing")
        sessionManager.currentCastSession?.add(screenMirroringChannel!)
        connectFinished?(true)
        
    }
    
    /*
     */
    
    func sessionManager(_ sessionManager: GCKSessionManager, willEnd session: GCKSession) {
        print(">>>ChromeCast: Session is about to be ended")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, willEnd session: GCKCastSession) {
        print(">>>ChromeCast: Cast Session is about to be ended")
        let realm = try! Realm()
        let connectedDevices = realm.objects(DeviceObject.self).where { $0.isConnected == true }
        try! realm.write {
            for device in connectedDevices {
                device.isConnected = false
                realm.add(device, update: .all)
            }
        }
    }
    
    /*
     */
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        print(">>>ChromeCast: Session was ended with \(error?.localizedDescription ?? "by request")")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
        print(">>>ChromeCast: Cast Session was ended with \(error?.localizedDescription ?? "by request")")
        let realm = try! Realm()
        let connectedDevices = realm.objects(DeviceObject.self).where { $0.isConnected == true }
        try! realm.write {
            for device in connectedDevices {
                device.isConnected = false
                realm.add(device, update: .all)
            }
        }
    }
    
    /*
     */
    
    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKSession, withError error: Error) {
        connectFinished?(false)
        self.isSessionResumed = false
        print(">>>ChromeCast: Session has failed to start with Error: \(error.localizedDescription)")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
        connectFinished?(false)
        self.isSessionResumed = false
        print(">>>ChromeCast: Cast Session has failed to start with Error: \(error.localizedDescription)")
    }
    
    /*
     */
    
    func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKSession, with reason: GCKConnectionSuspendReason) {
        print(">>>ChromeCast: Session has been suspend wth reason: \(reason.rawValue)")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKCastSession, with reason: GCKConnectionSuspendReason) {
        print(">>>ChromeCast: Cast Session has been suspend wth reason: \(reason.rawValue)")
    }
    
    /*
     */
    
    func sessionManager(_ sessionManager: GCKSessionManager, willResumeSession session: GCKSession) {
        print(">>>ChromeCast: Session is about to be resumed.")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, willResumeCastSession session: GCKCastSession) {
        print(">>>ChromeCast: Cast session is about to be resumed.")
    }
    
    /*
     */
    
    func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
        print(">>>ChromeCast: Session has been successfully resumed.")
        connectFinished?(true)
        self.isSessionResumed = true
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        print(">>>ChromeCast: Cast Session has been successfully resumed.")
        self.screenMirroringChannel = GCKCastChannel(namespace:"urn:x-cast:com.mirroring.screen.sharing")
        sessionManager.currentCastSession?.add(screenMirroringChannel!)
        connectFinished?(true)
        self.isSessionResumed = true
    }
    
    /*
     */
    
    func sessionManager(_ sessionManager: GCKSessionManager, session: GCKSession, didUpdate device: GCKDevice) {
        //Called when the default session options have been changed for a given device category.
        print(">>>ChromeCast: Device associated with this session has changed")
    }
    
}


