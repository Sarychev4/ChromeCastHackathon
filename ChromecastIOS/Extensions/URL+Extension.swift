//
//  URL+Extension.swift
//  ScreenMirroring
//
//  Created by Vital on 29.11.21.
//

import Foundation

extension URL {
    static let GroupFolder = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroupId)!
    static let GroupRealmFile = GroupFolder.appendingPathComponent("GroupShared.realm") 
}
