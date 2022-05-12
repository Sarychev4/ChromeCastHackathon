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
    
//    let deviceScanner = GCKCastContext.sharedInstance().discoveryManager
    var foundedDevices: [GCKDevice] = []
    var screenMirroringChannel: GCKCastChannel?
    
    var connectFinish: ClosureBool?
    
    static let shared = ChromeCastService()
    
    private override init(){
        
    }
    
    func initialize() {
        print(">>> INITIALIZE")
        let criteria = GCKDiscoveryCriteria(applicationID: kReceiverAppID)
        let options = GCKCastOptions(discoveryCriteria: criteria)
        options.disableDiscoveryAutostart = true
//        options.disableAnalyticsLogging = true;
        options.stopReceiverApplicationWhenEndingSession = true;
        options.physicalVolumeButtonsWillControlDeviceVolume = true;
        options.startDiscoveryAfterFirstTapOnCastButton = false;
        GCKCastContext.setSharedInstanceWith(options)
        GCKLogger.sharedInstance().delegate = self
        let deviceScanner = GCKCastContext.sharedInstance().discoveryManager
        deviceScanner.add(self)
        deviceScanner.startDiscovery()
        
        let sessionManager = GCKCastContext.sharedInstance().sessionManager
        print(sessionManager.hasConnectedSession())
        if sessionManager.hasConnectedSession(){
            sessionManager.endSession()
        }
        sessionManager.add(self)
        
    }
    
    func connect(to deviceID: String, onComplete: ClosureBool?) {
        print("DeviceID \(deviceID)")
        let deviceScanner = GCKCastContext.sharedInstance().discoveryManager
        guard let device = deviceScanner.device(withUniqueID: deviceID) else { return }
        
        print("DeviceID from scanner \(device.deviceID)")
        startNewSession(with: device)
        connectFinish = onComplete
    }
    
    func startNewSession(with device: GCKDevice){
        let sessionManager = GCKCastContext.sharedInstance().sessionManager
        sessionManager.startSession(with: device)
    }
    
    func displayImage(with url: URL) {
        
        let params = ["type": "image", "url": url.absoluteString]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: params, options: [])
            guard let convertedString = String(data: jsonData, encoding: String.Encoding.utf8) else {return}
            screenMirroringChannel?.sendTextMessage(convertedString, error: nil)
        } catch {
            print(error.localizedDescription)
        }
    }
 
}

extension ChromeCastService: GCKLoggerDelegate {
    func logMessage(_ message: String, at level: GCKLoggerLevel, fromFunction function: String, location: String) {
        if (kDebugLoggingEnabled) {
            print(function + " - " + message)
        }
    }
}

extension ChromeCastService: GCKDiscoveryManagerListener {
    
    func didInsert(_ device: GCKDevice, at index: UInt) { //called when device was discovered and added into devicelist
        
        let deviceObj = DeviceObject()
        deviceObj.deviceID = device.deviceID
        deviceObj.deviceUniqueID = device.uniqueID
        deviceObj.friendlyName = device.friendlyName ?? "No friendly name"
        deviceObj.modelName = device.modelName ?? "No model name"
        let realm = try! Realm()
        try! realm.write {
            realm.add(deviceObj, update: .all)
        }
        
        self.foundedDevices.append(device)
    }
    
    func didRemove(_ device: GCKDevice, at index: UInt) { //called when device was removed from devicelist
        let realm = try! Realm()
        guard let deviceObj = realm.object(ofType: DeviceObject.self, forPrimaryKey: device.deviceID) else { return }
        try! realm.write({
            realm.delete(deviceObj)
        })
        self.foundedDevices.remove(at: Int(index))
    }
}

extension ChromeCastService: GCKSessionManagerListener {
    func sessionManager(_ sessionManager: GCKSessionManager, willStart session: GCKSession) {
        print("Session will start")
        screenMirroringChannel = GCKCastChannel(namespace:"urn:x-cast:com.mirroring.screen.sharing")
        sessionManager.currentCastSession?.add(screenMirroringChannel!)
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        print("Session did start")
        connectFinish?(true)
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKSession, withError error: Error) {
        print("Session Not started")
        connectFinish?(false)
        print(error.localizedDescription)
    }
    
}



