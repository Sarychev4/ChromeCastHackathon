//
//  UIFont+Extension.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 19.04.2022.
//

import Foundation
import UIKit

public extension UIFont {
    static func customFont(weight: UIFont.Weight = .regular, size: CGFloat) -> UIFont {
        
        switch weight {
        case .regular:
            return UIFont.systemFont(ofSize: size * SizeFactor, weight: .regular)
        case .medium:
            return UIFont.systemFont(ofSize: size * SizeFactor, weight: .medium)
        case .semibold:
            return UIFont.systemFont(ofSize: size * SizeFactor, weight: .semibold)
        case .bold:
            return UIFont.systemFont(ofSize: size * SizeFactor, weight: .bold)
        case .heavy:
            return UIFont.systemFont(ofSize: size * SizeFactor, weight: .black)
        case .light:
            return UIFont.systemFont(ofSize: size * SizeFactor, weight: .light)
        case .black:
            return UIFont.systemFont(ofSize: size * SizeFactor, weight: .black)
        case .thin:
            return UIFont.systemFont(ofSize: size * SizeFactor, weight: .thin)
        case .ultraLight:
            return UIFont.systemFont(ofSize: size * SizeFactor, weight: .ultraLight)
        default:
            return UIFont.systemFont(ofSize: size * SizeFactor, weight: .regular)
        }
    }
    
    var weight: UIFont.Weight {
        guard let weightNumber = traits[.weight] as? NSNumber else { return .regular }
        let weightRawValue = CGFloat(weightNumber.doubleValue)
        let weight = UIFont.Weight(rawValue: weightRawValue)
        return weight
    }
    
    private var traits: [UIFontDescriptor.TraitKey: Any] {
        return fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any] ?? [:]
    }
}
