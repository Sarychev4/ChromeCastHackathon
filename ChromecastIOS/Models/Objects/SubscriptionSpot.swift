//
//  SubscriptionSpot.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 10.05.2022.
//

import Foundation
import RealmSwift

@objc
enum SubscriptionSpotPresentationStyle: Int, RealmEnum {
    case modal, fade
    
    public var stringValue: String! {
        get {
            let map: [SubscriptionSpotPresentationStyle: String] = [.modal: "modal", .fade: "fade"]
            return map[self]!
        }
    }
    
    public init?(stringValue: String) {
        let map: [String: SubscriptionSpotPresentationStyle] = ["modal": .modal, "fade": .fade]
        if let value = map[stringValue] {
            self = value
        } else {
            return nil
        }
    }
}

class SubscriptionSpot: Object {
    
    /*
     MARK: -
     */
    
    @objc dynamic var title: String! //temp as persisted
    
    @Persisted var specialOfferConfiguration: String!
    
    @Persisted var isEnabled: Bool = false
    
    @Persisted var currentActionsCount: Int = 0
    
    @Persisted var actionsCountToStart: Int = 0
    
    @Persisted var actionsCountToSkipAfterStart: Int = 0
    
    @Persisted var isSpecialOfferEnabled: Bool = true
    
    @objc
    dynamic var presentationStyle: SubscriptionSpotPresentationStyle = .modal
    
    /*
     Сдесь хранится полная конфигурация для Spot
     с кастомными настройками.
     */
    
    @Persisted var data: Data? = nil
    
    /*
     MARK: -
     */
    
    func getValue(for key: String, locale: String? = nil) -> AnyHashable? {
        guard let data = data, let JSON = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyHashable], let value = JSON[key] else {
            return nil
        }
        
        return value.localizedValue
    }
    
    
    @objc
    dynamic var specialOfferdata: Data? = nil
    
    /*
     MARK: -
     */
    
    func getSpecialOfferValue(for key: String, locale: String? = nil) -> AnyHashable? {
        guard let data = specialOfferdata, let JSON = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyHashable], let value = JSON[key] else {
            return nil
        }
        
        return value.localizedValue
    }
    
}
