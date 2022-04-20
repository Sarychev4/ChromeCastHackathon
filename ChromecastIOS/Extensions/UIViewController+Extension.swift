//
//  UIViewController+Extension.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 19.04.2022.
//

import UIKit

extension UIViewController {
    func add(_ child: UIViewController, container: UIView? = nil, frame: CGRect? = nil) {
        addChild(child)

        if let frame = frame {
            child.view.frame = frame
        } else if let container = container {
            child.view.frame = container.frame
        }

        child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container?.addSubview(child.view)
        //view.addSubview(child.view)
        child.didMove(toParent: self)
    }

    func remove() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}


extension UIViewController {
    
    var navigation: UINavigationContainer? {
        get {
            return parent as? UINavigationContainer
        }
    }
    
}
