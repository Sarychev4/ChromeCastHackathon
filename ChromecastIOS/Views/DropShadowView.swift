//
//  DropShadowView.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 19.04.2022.
//

import UIKit

class DropShadowView: DefaultView {
    @IBInspectable var shadowRadius: CGFloat = 3
    @IBInspectable var shadowOpacity: CGFloat = 0.2
    @IBInspectable var isRounded: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupShadow(cornerRadius: cornerRadius, shadowRadius: shadowRadius, shadowOpacity: shadowOpacity)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isRounded {
            layer.cornerRadius = frame.size.height / 2
        }
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }

}
