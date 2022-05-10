//
//  LocalNetworkManager.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 10.05.2022.
//

import Foundation

class LocalNetworkPermissionsManager {
    static let shared = LocalNetworkPermissionsManager()
    private var running = false
    func checkUserPermissonsLocalNetwork(onComplete: @escaping (Bool) -> () ) {
        if #available(iOS 14, *) {
            guard running == false else { return }
            running = true
            GetLocalNetworkAccessState { [weak self] granted in
                DispatchQueue.main.async {
                    self?.running = false
                    onComplete(granted)
                }
            }
        } else {
            DispatchQueue.main.async { onComplete(true) }
        }
    }
}

class GetLocalNetworkAccessState: NSObject, NetServiceDelegate {
   var service: NetService
   var denied: DispatchWorkItem?
   var completion: ((Bool) -> Void)
   
   @discardableResult
   init(completion: @escaping (Bool) -> Void) {
       self.completion = completion
       
       service = NetService(domain: "local.", type:"_lnp._tcp.", name: "LocalNetworkPrivacy", port: 1100)
       
       super.init()
       
       denied = DispatchWorkItem {
           self.completion(false)
           self.service.stop()
           self.denied = nil
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: denied!)
       
       service.delegate = self
       self.service.publish()
   }
    
    func netServiceDidPublish(_ sender: NetService) {
        service.stop()
        denied?.cancel()
        denied = nil
        completion(true)
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
    }
}
