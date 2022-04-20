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
