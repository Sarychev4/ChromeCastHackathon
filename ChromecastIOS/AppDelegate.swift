//
//  AppDelegate.swift
//  ChromecastIOS
//
//  Created by Vital on 19.04.22.
//

import UIKit
import RealmSwift 
import GoogleCast
import AppTrackingTransparency
import AdSupport
import GCDWebServer

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
//    var server: CRHTTPServer?
    var webServer: GCDWebServer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
         
        /*
         */
        
        webServer = GCDWebServer()
        
        webServer?.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: {request in
                    return GCDWebServerDataResponse(html:"<html><body><p>Hello World</p></body></html>")
        })
        
        webServer?.addHandler(forMethod: "GET", path: "/faq", request: GCDWebServerRequest.self, asyncProcessBlock: { request, complitionBlock in

            let faqPath = Bundle.main.bundlePath.appending("/FAQ.html")
            let response = GCDWebServerFileResponse(file: faqPath, byteRange: request.byteRange)
            complitionBlock(response)
        })
        
        webServer?.addHandler(forMethod: "GET", pathRegex: "/playerPreviewImage/.*", request: GCDWebServerRequest.self, asyncProcessBlock: { request, complitionBlock in
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let imageFileURL = documentsDirectory.appendingPathComponent("previewImage.jpg")
            let response = GCDWebServerFileResponse(file: imageFileURL.path, byteRange: request.byteRange)
            complitionBlock(response)
        })
    
        webServer?.addHandler(forMethod: "GET", pathRegex: "/image/.*", request: GCDWebServerRequest.self, asyncProcessBlock: { request, complitionBlock in
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let imageFileURL = documentsDirectory.appendingPathComponent("imageForCasting.jpg")
            let response = GCDWebServerFileResponse(file: imageFileURL.path, byteRange: request.byteRange)
            complitionBlock(response)
        })

        webServer?.addHandler(forMethod: "GET", pathRegex: "/video/.*", request: GCDWebServerRequest.self, asyncProcessBlock: { request, complitionBlock in
        
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let imageFileURL = documentsDirectory.appendingPathComponent("videoForCasting.mp4")
            let response = GCDWebServerFileResponse(file: imageFileURL.path, byteRange: request.byteRange)
            complitionBlock(response)

//            guard let assetPath = UserDefaults.standard.lastVideoAssetPath else { return } //temp vr 1!!!
//            let response = GCDWebServerFileResponse(file: assetPath, byteRange: request.byteRange)
//            complitionBlock(response)
        })
        
//        GCDWebServerOption_AutomaticallySuspendInBackground
        webServer?.start(withPort: Port.app.rawValue, bonjourName: "GCD web server")
        print("Visit \(String(describing: webServer?.serverURL)) in your web browser")
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        /*
         */
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        /*
         */
        
      
         
        /*
         */
        
        DataManager.shared.initialize()
        
        /*
         */
        
        let loadingViewController = LoadingViewController()
        loadingViewController.didFinishAction = { [weak self] in
            guard let self = self else { return }
            
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    guard status == .authorized else {return}
                    let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                  
                }
            }
            
            DataManager.shared.updateData()
            if Settings.current.isIntroCompleted {
                DataManager.shared.setupSpecialOfferTimer()
                self.showMainViewController()
//                SubscriptionSpotsManager.shared.requestSpot(for: DataManager.SubscriptionSpotType.sessionStart.rawValue) { [weak self] success in
//                    guard let self = self else { return }
//                    self.showMainViewController()
//                }
            } else {
                
                self.showMainViewController()

            }
        }
        
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = loadingViewController
        window!.makeKeyAndVisible()
        
        
        return true
    }
    
    
    func showMainViewController() {
        let viewController = MainViewController()
        let navigationController = UINavigationContainer(rootViewController: viewController)
        
        window!.rootViewController = navigationController
        window!.layer.add(CATransition(), forKey: nil)
    }
      
}

extension AppDelegate {
    func applicationWillEnterForeground(_ application: UIApplication) {
        ChromeCastService.shared.startDiscovery()
    }
    
    func endBackgroundUpdateTask() {
        
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
       
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        
    }
}
