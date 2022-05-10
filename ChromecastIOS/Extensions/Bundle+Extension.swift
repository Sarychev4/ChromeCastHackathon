//
//  Bundle+Extension.swift
//  ScreenSharing
//  Created by Vital on 4.10.21.
//

import Foundation

extension Bundle {
    var buildVersionNumber: String {
        return "\(Bundle.main.infoDictionary!["CFBundleVersion"]!)"
    }
}
