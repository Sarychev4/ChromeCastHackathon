//
//  AnyHashable+Extension.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 10.05.2022.
//

import Foundation

extension AnyHashable {
    
    var localizedValue : AnyHashable {
        if let dictionary = self as? [String: AnyHashable] {
            let locale = Locale.preferredLocale.identifier
            let components = locale.components(separatedBy: "-")
            if let localizedValue = dictionary[locale] {
                return localizedValue
            } else if let firstComponent = components.first, let localizedValue = dictionary[firstComponent] {
                return localizedValue
            } else if let localizedValue = dictionary["en"] {
                return localizedValue
            }
        }
        
        return self
    }
    
}
