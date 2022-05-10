//
//  Locale+Extension.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 10.05.2022.
//

import Foundation

extension Locale {
    
    static var isGerman: Bool {
        return Locale.current.languageCode == "de"
    }
    
    static var preferredLocale: Locale {
        guard let preferredIdentifier = Locale.preferredLanguages.first else {
            return Locale.current
        }
        
        return Locale(identifier: preferredIdentifier)
    }
    
}
