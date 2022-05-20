//
//  ChromeCastService.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 05.05.2022.
//

import Foundation
import GoogleCast
import RealmSwift

class ChromeCastService: NSObject {
    
    let kReceiverAppID = "2C5BA44D"
    let kDebugLoggingEnabled = true
    
    static let shared = ChromeCastService()
    
    var foundedDevices: [GCKDevice] = []
    var screenMirroringChannel: GCKCastChannel?
    
    var sessionManager: GCKSessionManager?
    
    var currentConnectedDeviceID: String?
    
    var connectFinished: ClosureBool?
    
    private override init(){
        
    }
    
    func initialize() {
        print(">>>ChromeCast Service was initialized")
        let criteria = GCKDiscoveryCriteria(applicationID: kReceiverAppID)
        let options = GCKCastOptions(discoveryCriteria: criteria)
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
    }
    
    func connect(to deviceID: String, onComplete: ClosureBool?) {
        let deviceScanner = GCKCastContext.sharedInstance().discoveryManager
        guard let device = deviceScanner.device(withUniqueID: deviceID) else { return }
        
        startNewSession(with: device)
        self.connectFinished = onComplete
        
    }
    
    func startNewSession(with device: GCKDevice){
        self.sessionManager!.startSession(with: device)
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
    
    func displayIPTVBeam(with url: URL) {
        let metadata = GCKMediaMetadata(metadataType: .movie)
        let mediaInfoBuilder = GCKMediaInformationBuilder(contentURL: url)
        mediaInfoBuilder.contentType = "video/mp4" //mediaInfo.mimeType
        mediaInfoBuilder.streamType = GCKMediaStreamType.none
        mediaInfoBuilder.metadata = metadata
        let mediaInformation = mediaInfoBuilder.build()
        let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
        remoteMediaClient?.loadMedia(mediaInformation)
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
        print(">>>ChromeCast: Session has failed to start with Error: \(error.localizedDescription)")
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
        connectFinished?(false)
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
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        print(">>>ChromeCast: Cast Session has been successfully resumed.")
        self.screenMirroringChannel = GCKCastChannel(namespace:"urn:x-cast:com.mirroring.screen.sharing")
        sessionManager.currentCastSession?.add(screenMirroringChannel!)
        connectFinished?(true)
    }
    
    /*
     */
    
    func sessionManager(_ sessionManager: GCKSessionManager, session: GCKSession, didUpdate device: GCKDevice) {
        //Called when the default session options have been changed for a given device category.
        print(">>>ChromeCast: Device associated with this session has changed")
    }
    
}


