//
//  Constants.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 19.04.2022.
//

import Foundation
import DeviceKit

/*
 */

public var SizeFactor: CGFloat = ((Device.current.diagonal == Device.iPhoneX.diagonal || Device.current.diagonal == Device.iPhoneXS.diagonal || Device.current.diagonal == Device.iPhoneXSMax.diagonal || Device.current.diagonal == Device.iPhoneXR.diagonal || Device.current.diagonal == Device.iPhone11.diagonal || Device.current.diagonal == Device.iPhone11Pro.diagonal || Device.current.diagonal == Device.iPhone11ProMax.diagonal) || Device.current.diagonal == Device.iPhoneSE2.diagonal || Device.current.diagonal == Device.iPhone12Mini.diagonal || Device.current.diagonal == Device.iPhone12.diagonal || Device.current.diagonal == Device.iPhone12Pro.diagonal || Device.current.diagonal == Device.iPhone12ProMax.diagonal || Device.current.diagonal == Device.iPhone13Mini.diagonal || Device.current.diagonal == Device.iPhone13.diagonal || Device.current.diagonal == Device.iPhone13Pro.diagonal || Device.current.diagonal == Device.iPhone13ProMax.diagonal ? UIScreen.main.bounds.width / 375 : UIScreen.main.bounds.height / 667)

public let JPEGQuality: CGFloat = 0.5

public let DefaultCornerRadius: CGFloat = 16 * SizeFactor

public let ImageSize = CGSize(width: 1080, height: 1350)

public typealias Closure = () -> Void
public typealias ClosureBool = (Bool) -> Void
public typealias ClosureURL = (URL?, Error?) -> Void
public typealias ClosureSuccess = (Bool?, Error?) -> Void

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


