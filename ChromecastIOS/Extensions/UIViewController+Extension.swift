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
    
    func removeAllSubviewsIn(container: UIView) {
        for view in container.subviews {
            view.removeFromSuperview()
        }
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

public var TopViewController: UIViewController? {
    guard let window = UIApplication.shared.keyWindow else {
        return nil
    }
    
    /*
     */
    
    var viewController: UIViewController? = nil
    var topViewController = window.rootViewController
    
    while viewController == nil {
        if topViewController?.presentedViewController == nil {
            viewController = topViewController
        } else {
            topViewController = topViewController?.presentedViewController
        }
    }
    
    /*
     */
    
    if let navigationController = topViewController as? UINavigationController, let lastViewController = navigationController.viewControllers.last {
        topViewController = lastViewController
    }
    
    return topViewController
}
