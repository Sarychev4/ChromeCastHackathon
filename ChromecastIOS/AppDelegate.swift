//
//  AppDelegate.swift
//  ChromecastIOS
//
//  Created by Vital on 19.04.22.
//

import UIKit
import RealmSwift 
import Agregator
import GoogleCast
import Firebase
import AppTrackingTransparency
import AdSupport
import ApphudSDK
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
        
        Agregator.shared.initialize(
            applicationID: "1620128676",
            amplitudeAPIKey: "a9ab440a6e5b2968cfe176520ea091f7",
            apphudAPIKey: "app_HARkZgrMoU5oAsLqx1fGcyPFQGhL8b",
            appsFlyerAPIKey: "mVN6DoQzLUCxz7gLjQivSY"
        )
         
        /*
         */
        
        DataManager.shared.initialize()
        
        /*
         */
        
        let loadingViewController = LoadingViewController()
        loadingViewController.didFinishAction = { [weak self] in
            guard let self = self else { return }
            
//            if #available(iOS 14, *) {
//                ATTrackingManager.requestTrackingAuthorization { status in
//                    guard status == .authorized else {return}
//                    let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
//                    Apphud.setAdvertisingIdentifier(idfa)
//                }
//            }
            
            
            if Settings.current.isIntroCompleted {
                DataManager.shared.setupSpecialOfferTimer()
                SubscriptionSpotsManager.shared.requestSpot(for: DataManager.SubscriptionSpotType.sessionStart.rawValue) { [weak self] success in
                    guard let self = self else { return }
                    self.showMainViewController()
                }
            } else {
                self.showTutorial()
            }
        }
        
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = loadingViewController
        window!.makeKeyAndVisible()
        
        
        return true
    }
    
    func showTutorial() {
        let vc = TutorialContainerViewController()
        let navigationController = DefaultNavigationController(rootViewController: vc)
        navigationController.isNavigationBarHidden = false
        
        window!.layer.add(CATransition(), forKey: nil)
        window!.rootViewController = navigationController
        
        vc.didFinishAction = {
            try! Settings.current.realm?.write {
                Settings.current.isIntroCompleted = true
            }
            
            DataManager.shared.setupSpecialOfferTimer()
            
            SubscriptionSpotsManager.shared.requestSpot(for: DataManager.SubscriptionSpotType.intro.rawValue, with: { [weak self] success in
                SubscriptionSpotsManager.shared.requestSpot(for: DataManager.SubscriptionSpotType.introSpecialOffer.rawValue, with: { [weak self] success in
                    self?.showMainViewController()
                })
            })
        }
        
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
