//
//  Settings.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 10.05.2022.
//

import UIKit
import RealmSwift
import Agregator

@objc
enum SpecialOfferState: Int, PersistableEnum {
    case none, running, completed
}

class Settings: Object {
    
    static let PrimaryKey = "SettingsId"
    
    static public var current: Settings {
        let realm = try! Realm()
        return realm.object(ofType: Settings.self, forPrimaryKey: Settings.PrimaryKey)!
    }
    
    /*
     MARK: -
     */
    
    @Persisted(primaryKey: true) var id = "SettingsId"
    
    @Persisted var isFirstSetup: Bool = true
     
    @Persisted var isDiscoveryAvailable: Bool = false
    
    @Persisted var isUserAttributionEnabled: Bool = false // Пользователь скачал приложение тапнув на рекламу
    
    @Persisted var hideCloseButtonForAttributedUser: Bool = false // Пользователь скачал приложение тапнув на рекламу
    
    /*
     MARK: -
     */
    
    @Persisted var ratingImpressionsMaxCountPerSession: Int = 1
    
    @Persisted var ratingImpressionsCurrentCount: Int = 0
     
    @Persisted var ratingReviewURLString: String?
    
    /*
     MARK: - Subscriptions
     */
    
    /*
     Оставшееся время в секундах.
     */
    
    @Persisted var specialOfferStartDate: Double = 0
    
    @Persisted var specialOfferTime: Double = 3600
    
    @objc @Persisted var specialOfferTimeLeft: Double = 3600 //temp as
    
    @Persisted var specialOfferState: SpecialOfferState = .none
    
    @Persisted var isSpecialOfferEnabled: Bool = true

    var isNeedToShowSpecialOffer: Bool {
        get {
            return (AgregatorApplication.current.subscriptionState == .none || AgregatorApplication.current.subscriptionState == .expired || AgregatorApplication.current.subscriptionState == .customTrialExpired) && Settings.current.specialOfferState != .completed && isSpecialOfferEnabled
        }
    }
    
    //MARK: - Media Cast Settings
    
    @Persisted var photosResolution: ResolutionType = .medium
    
    @Persisted var videosResolution: ResolutionType = .medium
    
    @Persisted var youtubeResolution: ResolutionType = .medium
    
    /*
     MARK: - Intro
     */
    
    @Persisted var isIntroCompleted: Bool = false
    
    @Persisted var introSkipEnabled: Bool = true
    
    @Persisted var introQuestionsEnabled: Bool = false
    
    @Persisted var introRatingEnabled: Bool = false
    
    @Persisted var introContinueAnimationDuration: Double = 2
    
    @Persisted var introConfiguringDuration: Double = 10
    
    @Persisted var introRatingType: String = "stars"
    
    /*
     MARK: - Connection with TV
     */
    
    @Persisted var mirroringState: MirroringInAppState = .mirroringNotStarted
    
    @Persisted var supportEmail: String = "supportsm@appflair.io"
    
}
