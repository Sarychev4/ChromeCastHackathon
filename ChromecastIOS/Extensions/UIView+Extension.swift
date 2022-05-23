//
//  UIView+Extension.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 19.04.2022.
//

import UIKit

extension UIView {
    static var nib: UINib {
        return UINib(nibName: "\(self)", bundle: nil)
    }
    
    static func fromNib() -> Self? {
        return nib.instantiate() as? Self
    }
    
    var allSubviews: [UIView] {
        return self.subviews.flatMap { [$0] + $0.allSubviews }
    }
    
}

extension UINib {
    func instantiate() -> Any? {
        return instantiate(withOwner: nil, options: nil).first
    }
}

public extension UIView {
    
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
    func bindToSuperview(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) {
        guard let superview = superview else {
            return
        }
        
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: superview.topAnchor, constant: top).isActive = true
        superview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: bottom).isActive = true
        leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: left).isActive = true
        superview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: right).isActive = true
    }
    
    func bounce(onComplete: (() -> ())?) {
        UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction], animations: {
            self.transform = CGAffineTransform.identity.scaledBy(x: 1.05, y: 1.05)
        }) { (isFinished) in
            UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction], animations: {
                self.transform = CGAffineTransform.identity
            }) { (isFinished) in
                UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction], animations: {
                    self.transform = CGAffineTransform.identity.scaledBy(x: 1.05, y: 1.05)
                }) { (isFinished) in
                    UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction], animations: {
                        self.transform = CGAffineTransform.identity
                    }) { (isFinished) in
                        UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction], animations: {
                            self.transform = CGAffineTransform.identity.scaledBy(x: 1.05, y: 1.05)
                        }) { (isFinished) in
                            UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction], animations: {
                                self.transform = CGAffineTransform.identity
                            }) { (isFinished) in
                                self.transform = CGAffineTransform.identity
                                onComplete?()
                            }
                        }
                    }
                }
            }
        }
    }
}
extension UIView {
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
}

extension UIView {
    
    func addDropShadow() {
        let vw = self
        if vw.layer.shadowRadius != 5 {
            vw.layer.shadowRadius = 5
            vw.layer.shadowPath = UIBezierPath(rect: vw.bounds).cgPath
            vw.layer.shadowOffset = .zero
            vw.layer.shadowOpacity = 0.8
        }
    }
    
    func setupShadow(cornerRadius: CGFloat = 0.0, shadowRadius: CGFloat = 8, shadowColor: UIColor = .black, shadowOffset: CGSize = CGSize.zero, shadowOpacity: CGFloat = 0.4, customPath: UIBezierPath? = nil) {
        let viewWithShadow = self
        if  cornerRadius > 0 {
            viewWithShadow.layer.cornerRadius = cornerRadius
        }
        viewWithShadow.layer.shadowRadius = shadowRadius
        viewWithShadow.layer.shadowColor = shadowColor.cgColor
        viewWithShadow.layer.shadowOffset = shadowOffset
        viewWithShadow.layer.shadowOpacity = Float(shadowOpacity)
        viewWithShadow.layer.masksToBounds = false
        //        viewWithShadow.layer.shouldRasterize = true
        let shadowPath = customPath ??  UIBezierPath(roundedRect: viewWithShadow.bounds, cornerRadius: viewWithShadow.layer.cornerRadius)
        viewWithShadow.layer.shadowPath = shadowPath.cgPath
        viewWithShadow.layer.shouldRasterize = true
        viewWithShadow.layer.rasterizationScale = UIScreen.main.scale
    }
}


public extension UIView {
    /// SwifterSwift: Border color of view; also inspectable from Storyboard.
    @IBInspectable var borderColor: UIColor? {
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
        set {
            guard let color = newValue else {
                layer.borderColor = nil
                return
            }
            // Fix React-Native conflict issue
            guard String(describing: type(of: color)) != "__NSCFType" else { return }
            layer.borderColor = color.cgColor
        }
    }
    
    /// SwifterSwift: Border width of view; also inspectable from Storyboard.
    @IBInspectable var borderWidth: CGFloat {
        get {
            layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
}

extension NSObject {
    var className: String {
        return String(describing: type(of: self))
    }
    
    class var className: String {
        return String(describing: self)
    }
}

extension UITableViewHeaderFooterView {
    class var Identifier: String {
        return className
    }
}

extension UITableViewCell {
    class var Identifier: String {
        return className
    }
}

extension UICollectionViewCell {
    class var Identifier: String {
        return className
    }
}
