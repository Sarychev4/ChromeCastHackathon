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
import GoogleSignIn
import Criollo

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var server: CRHTTPServer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
         
        
        /*
         */
        server = CRHTTPServer()
        var serverError: NSError?
        
        server?.mount("/faq", fileAtPath:  Bundle.main.bundlePath.appending("/FAQ.html"))
        server?.get("/image/:id", block: { [weak self] (req, res, next) in
            guard let _ = self else { return }
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let imageFileURL = documentsDirectory.appendingPathComponent("imageForCasting.jpeg")
            guard let image = UIImage(contentsOfFile: imageFileURL.path) else { return }
            guard let data = image.jpegData(compressionQuality: 0.9) else { return }
            res.setValue("image/jpeg", forHTTPHeaderField: "Content-type")
            res.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
            res.send(data)
        })


        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return false}
        let videoFileURL = documentsDirectory.appendingPathComponent("videoForCasting.mp4")
        server?.mount("/video/:id", fileAtPath: videoFileURL.path, options: .followSymlinks, fileName: nil, contentType: nil,  contentDisposition: .attachment)

        server?.get("/") { (req, res, next) in
            res.send("Hello world!")
        }
        
        server?.startListening(&serverError, portNumber: Port.app.rawValue)
        
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
        
        
        /*
         */
        
        var realmConfig = Realm.Configuration()
        realmConfig.schemaVersion = 1
        Realm.Configuration.defaultConfiguration = realmConfig
        
        /*
         */
        
        DataManager.shared.initialize()
        
        /*
         */
        
        let loadingViewController = LoadingViewController()
        loadingViewController.didFinishAction = { [weak self] in
            guard let self = self else { return }
            
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
        
        print("Realm is here: \(Realm.Configuration.defaultConfiguration.fileURL!.path)")
        
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
    
    // MARK: UISceneSession Lifecycle
    
    //    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    //        // Called when a new scene session is being created.
    //        // Use this method to select a configuration to create the new scene with.
    //        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    //    }
    //
    //    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    //        // Called when the user discards a scene session.
    //        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    //        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    //    }
    
    
}

