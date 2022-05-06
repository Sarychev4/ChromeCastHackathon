//
//  AppDelegate.swift
//  ChromecastIOS
//
//  Created by Vital on 19.04.22.
//

import UIKit
import RealmSwift
import GoogleCast

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        var realmConfig = Realm.Configuration()
        realmConfig.schemaVersion = 1
        Realm.Configuration.defaultConfiguration = realmConfig
        
//        let viewController = MainViewController()
//        let navigationController = UINavigationContainer(rootViewController: viewController)
        
        let vc = TutorialContainerViewController()
        vc.didFinishAction = {
            let viewController = MainViewController()
            let navigationController = UINavigationContainer(rootViewController: viewController)

            self.window!.layer.add(CATransition(), forKey: nil)
            self.window!.rootViewController = navigationController
        }
        let navigationController = DefaultNavigationController(rootViewController: vc)
        navigationController.isNavigationBarHidden = false

        
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.layer.add(CATransition(), forKey: nil)
        window!.rootViewController = navigationController
        window!.makeKeyAndVisible()
        
        return true
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

