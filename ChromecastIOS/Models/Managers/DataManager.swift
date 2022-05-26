//
//  DataManager.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 10.05.2022.
//

import RealmSwift
import Agregator
import Alamofire
import UIKit
import StoreKit
import AdServices
import iAd

let SpecialOfferTime: Double = 3600

enum ResponseStatus {
    case none, success, timeout, error
}

class DataManager: NSObject {
    
    let TimeoutInterval: Double = 5
    
    /*
     MARK: -
     */
    
    enum TutorialStepName: String, CaseIterable {
        case review = "TutorialReview"
        case connect = "TutorialConnect"
        case access = "TutorialAccess"
        case demo = "TutorialDemo"
        case network = "TutorialNetwork"
        case selectDevices = "TutorialSelectDevices"
        case selectFeatures = "TutorialSelectFeatures"
        case notifications = "TutorialNotifications"
    }
    
    enum RatingSpotName: String {
        case afterTutorial = "on_after_tutorial"
        case rateTheApp = "rate_the_app"
    }

    enum PushSpotType: String {
        case sessionStart = "session_start"
        case exitFromPresets = "exit_from_presets"
    }
    
    enum SubscriptionSpotType: String, CaseIterable {
        case intro = "intro" // После туториала
        case introSpecialOffer = "introSpecialOffer" // После туториала
        case sessionStart = "session_start"// При входе в приложение
        case settings = "settings" // Баннер на экране настроек
        case banner = "banner" // Баннер на главном экране
        case iptv = "iptv" // При попытке каста iptv на TV
        case browser = "browser" // При попытке каста видео на TV
        case youtube = "you_tube" // При попытке каста видео на TV
        case resolution = "resolution"
        case mirroringWithSound = "sound"
    }
    
    
    static let shared = DataManager()

    var networkReachabilityManager: NetworkReachabilityManager!
    var specialOfferTimer: Timer?

    /*
     MARK: - Initialize
     */
    
    func initialize(){
        
        setupRealm()
        
        var streamInfo = Realm.GroupShared.object(ofType: StreamConfiguration.self, forPrimaryKey: StreamConfiguration.PrimaryKey)
        if streamInfo == nil {
            streamInfo = StreamConfiguration()
            streamInfo!.id = StreamConfiguration.PrimaryKey
            try? Realm.GroupShared.write {
                Realm.GroupShared.add(streamInfo!)
            }
        }
        
        let realm = try! Realm()
        realm.beginWrite()
        
        var settings = realm.object(ofType: Settings.self, forPrimaryKey: Settings.PrimaryKey)
        if settings == nil {
            settings = Settings()
            settings!.id = Settings.PrimaryKey
            settings!.specialOfferTimeLeft = SpecialOfferTime
            realm.add(settings!)
        }
        
        func createSubscriptionSpot(_ type: SubscriptionSpotType) {
            var spot = realm.objects(SubscriptionSpot.self).filter("\(#keyPath(SubscriptionSpot.title)) == '\(type.rawValue)'").first
            if spot == nil {
                spot = SubscriptionSpot()
                spot!.isSpecialOfferEnabled = false
                spot!.title = type.rawValue
                spot!.isEnabled = true
                realm.add(spot!)
            }
        }
        
        SubscriptionSpotType.allCases.forEach({ createSubscriptionSpot($0) })
        
        try! realm.commitWrite()
        
        /*
         */
        
        NotificationCenter.default.addObserver(self, selector: #selector(newSessionAction), name: AgregatorNewSessionNotificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackgroundAction), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForegroundAction), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        /*
         */
        
        networkReachabilityManager = NetworkReachabilityManager(host: "www.apple.com")
        networkReachabilityManager.startListening { status in
            print(">>>> Network status, is WiFi? - \(self.networkReachabilityManager.isReachableOnEthernetOrWiFi)")
        }
        
        checkApplicationAvailability()
        
    }
    
    private func setupRealm() {
        Realm.Configuration.defaultConfiguration = Realm.Main.configuration
        #if DEBUG
        print("\n\n>>> RealmFile: \n\(Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().path ?? "")\n")
        #endif
    }
    
    @objc
    private func didEnterBackgroundAction() {
        AgregatorLogger.shared.log(eventName: "Сustom session end", parameters: ["Source": TopViewController?.className])
    }
    
    @objc
    private func willEnterForegroundAction() {
        setupSpecialOfferTimer()
    }
    
    @objc
    func newSessionAction() {
        
        /*
         */
        
        try! Settings.current.realm?.write {
            Settings.current.ratingImpressionsCurrentCount = 0
        }
        
        /*
         */
        
        updateData()
        
        /*
         */
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            SubscriptionSpotsManager.shared.requestSpot(for: DataManager.SubscriptionSpotType.sessionStart.rawValue, with: { success in
//
//            })
//        }
    }
    
    private func updateData() {
        getConfiguration(with: nil)
    }
    
    public func setupSpecialOfferTimer() {
        guard Settings.current.specialOfferState != .completed else { return }
        
        /*
         */
        
        specialOfferTimer?.invalidate()
        
        /*
         Если Special Offer не был запущен, тогда запускаем его.
         */
        
        if Settings.current.specialOfferState == .none {
            try! Settings.current.realm?.write {
                Settings.current.specialOfferState = .running
                Settings.current.specialOfferStartDate = Date().timeIntervalSince1970
            }
        } else if Settings.current.specialOfferState == .running {
            try! Settings.current.realm?.write {
                let delta = Date().timeIntervalSince1970 - Settings.current.specialOfferStartDate
                Settings.current.specialOfferTimeLeft = Settings.current.specialOfferTime - delta
            }
        }
        
        guard Settings.current.specialOfferTimeLeft > 0 else {
            try! Settings.current.realm?.write {
                Settings.current.specialOfferTimeLeft = 0
                Settings.current.specialOfferState = .completed
            }
            return
        }
        
        /*
         */
        
        specialOfferTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (timer) in
            try! Settings.current.realm?.write {
                if Settings.current.specialOfferTimeLeft > 0 {
                    Settings.current.specialOfferTimeLeft -= 1
                } else {
                    Settings.current.specialOfferTimeLeft = 0
                    Settings.current.specialOfferState = .completed
                    
                    self?.specialOfferTimer?.invalidate()
                }
            }
        })
    }
    
    /*
     MARK: - Check Internet Connection
     */
    
    func checkConnection(with completeBlock: @escaping ((_ responseStatus: ResponseStatus) -> ())) {
        
        guard let googleUrl = URL(string: "https://google.com") else { return }
        let request = URLRequest(url: googleUrl, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: TimeoutInterval)
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = TimeoutInterval
        configuration.timeoutIntervalForResource = TimeoutInterval
        
        let session = URLSession(configuration: configuration)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                
                /*
                 */
                
                if let NSError = error as? NSError, NSError.code == -1001 {
                    AgregatorLogger.shared.log(eventName: "No Internet")
                    completeBlock(.timeout)
                    return
                }
                var status: ResponseStatus = .none
                if data != nil, error == nil, let response = response, response.isSuccess {
                    status = .success
                } else {
                    status = .error
                    AgregatorLogger.shared.log(eventName: "No Internet")
                }
                completeBlock(status)
            }
        }
        task.resume()
        session.finishTasksAndInvalidate()
    }
    
    /*
     MARK: - Check Application Availability
     */
    
    func checkApplicationAvailability() {
        guard let url = URL(string: "https://611cfc5a7d273a0017e2f565.mockapi.io/firebase/crashlitycs/configuration/check") else { return }
        AF.request(url).responseJSON {  [weak self] response in
            guard let _ = self, let value = response.value as? [Int] else { return }
            if value.first == 1 {
                AgregatorLogger.shared.log(eventName: "Application Terminated")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    fatalError()
                })
            }
        }
    }
    
    
    /*
     MARK: - Get configuration from FireBase or Default
     */
    
    func getConfiguration(with completion: Closure?) {
       
        /*
         Если еще ни разу не смогли скачать конфиг - записываем дефолтный из вшитого файла.
         */
        
        if Settings.current.isFirstSetup {
            let defaultAppConfiguration = DefaultAppConfiguration
            /*
             >>> ЕСЛИ КРЭШИТ ТУТ, то скорее всего ты добавил "\n", а надо "\\n"
             */
            let json = try! JSONSerialization.jsonObject(with: defaultAppConfiguration.data(using: .utf8)!, options: [.allowFragments]) as? [String: Any]
            self.parseConfiguration(from: json as! [String: AnyHashable])
        }

        if let configString = AgregatorManager.shared.remoteConfiguration?["common_configuration"] as? String,
           let data = configString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyHashable] {
            self.parseConfiguration(from: json)
        }
//        temp vr 1
        DispatchQueue.main.async {
            completion?()
        }
    }
    
    /*
     MARK: - Parse Configuration
     */
    
    private func parseConfiguration(from dictionary: [String: AnyHashable]) {
        
//        configureWebApps(from: dictionary["web_apps"] as? [String: AnyHashable])
        
        let realm = try! Realm()
        realm.beginWrite()
         
        Settings.current.isFirstSetup = false
        
         
        if let subscriptionsConfiguration = dictionary["subscriptions"] as? [String: AnyHashable] {
            
            if let spots = subscriptionsConfiguration["spots"] as? [String: AnyHashable], let configurations = subscriptionsConfiguration["configurations"] as? [String: AnyHashable] {
                for key in spots.keys {
                    guard let spotConfiguration = spots[key] as? [String: AnyHashable] else {
                        continue
                    }
                    
                    var subscriptionSpot = realm.objects(SubscriptionSpot.self).filter("\(#keyPath(SubscriptionSpot.title)) == '\(key)'").first
                    if subscriptionSpot == nil {
                        subscriptionSpot = SubscriptionSpot()
                        subscriptionSpot!.title = key
                        realm.add(subscriptionSpot!)
                    }
                    
                    if let value = spotConfiguration["is_enabled"] as? Bool {
                        subscriptionSpot!.isEnabled = value
                    }
                    
                    if let value = spotConfiguration["actions_count_befor_start"] as? Int {
                        subscriptionSpot!.actionsCountToStart = value + 1
                    }
                    
                    if let value = spotConfiguration["special_offer_configuration"] as? String {
                        subscriptionSpot!.specialOfferConfiguration = value
                    }
                    
                    if let value = spotConfiguration["actions_skip_count_after_start"] as? Int {
                        subscriptionSpot!.actionsCountToSkipAfterStart = value
                    }
                    
                    if let value = spotConfiguration["is_special_offer_enabled"] as? Bool {
                        subscriptionSpot!.isSpecialOfferEnabled = value
                    }
                    
                    if let value = spotConfiguration["presentation_style"] as? String, let presentationStyle = SubscriptionSpotPresentationStyle(stringValue: value) {
                        subscriptionSpot!.presentationStyle = presentationStyle
                    }
                    
                    if let configurationValue = spotConfiguration["configuration"] as? String, let configuration = configurations[configurationValue] as? [String: AnyHashable], let value = try? JSONSerialization.data(withJSONObject: configuration, options: .fragmentsAllowed) {
                        subscriptionSpot!.data = value
                    }
                    
                    if let configuration = subscriptionsConfiguration["special_offer"] as? [String: AnyHashable], let value = try? JSONSerialization.data(withJSONObject: configuration, options: .fragmentsAllowed) {
                        subscriptionSpot!.specialOfferdata = value
                    }
                }
            }
             
            /*
             Обновляем таймер для Special Offer, если он не был запущен.
             */
            
            if let specialOfferConfiguration = subscriptionsConfiguration["special_offer"] as? [String: AnyHashable] {
                if let value = specialOfferConfiguration["special_offer_time_value"] as? NSNumber {
                    if Settings.current.specialOfferState == .none {
                        Settings.current.specialOfferTime = value.doubleValue
                        Settings.current.specialOfferTimeLeft = value.doubleValue
                    }
                }
                
                if let value = specialOfferConfiguration["is_special_offer_enabled"] as? Bool {
                    Settings.current.isSpecialOfferEnabled = value
                }
            }
        }
        
        if let introSkipEnabled = dictionary["tutorial_skip_button_enabled"] as? Bool {
            Settings.current.introSkipEnabled = introSkipEnabled
        }
        
        if let hideCloseButtonForAttributedUser = dictionary["hide_close_button_for_attributedUser"] as? Bool {
            Settings.current.hideCloseButtonForAttributedUser = hideCloseButtonForAttributedUser
        }
        
        if let supportEmail = dictionary["support_email"] as? String {
            Settings.current.supportEmail = supportEmail
        }
        
        if let introQuestionsEnabled = dictionary["tutorial_questions_enabled"] as? Bool {
            Settings.current.introQuestionsEnabled = introQuestionsEnabled
        }
        
        if let introRatingEnabled = dictionary["tutorial_rating_enabled"] as? Bool {
            Settings.current.introRatingEnabled = introRatingEnabled
        }
        
        if let introRatingType = dictionary["tutorial_rating_type"] as? String {
            Settings.current.introRatingType = introRatingType
        }
        
        try! realm.commitWrite()
        
        /*
         */
    }
    
    
    
}
