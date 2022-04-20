//
//  DefaultLabel.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 19.04.2022.
//

import UIKit

open class DefaultLabel: UILabel {

    /*
     MARK: -
     */
    
    @IBInspectable open var isAutomaticalyResizeEnabled: Bool = false
    @IBInspectable open var localizationKey: String? = nil
    @IBInspectable open var isUppercased: Bool = false
    
    /*
     MARK: -
     */
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        /*
         */
        
        if isAutomaticalyResizeEnabled {
            font = UIFont.customFont(weight: font.weight, size: font.pointSize)
        }
        
        if let key = localizationKey {
            text = NSLocalizedString(key, comment: "")
        }
        
        if isUppercased {
            text = text?.uppercased()
        }
    }

}



extension UILabel {
    
}
