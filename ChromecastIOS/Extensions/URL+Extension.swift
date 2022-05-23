//
//  URL+Extension.swift
//  ScreenMirroring
//
//  Created by Vital on 29.11.21.
//

import Foundation
import CSSystemInfoHelper

extension URL {
    static let GroupFolder = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroupId)!
    static let GroupRealmFile = GroupFolder.appendingPathComponent("GroupShared.realm") 
}

extension URL {
    static var HTML_STREAM_FRAME_URL: URL? {
        return URL(string: "http://\(CSSystemInfoHelper.ipAddress):\(Port.htmlStreamPort.rawValue)/screenmirror")
    }
}

extension CSSystemInfoHelper {
    static var ipAddress: String? {
        let networkInterfaces = CSSystemInfoHelper.shared.networkInterfaces
        guard let interface = networkInterfaces?.filter({ $0.name == "en0" && $0.familyName == "AF_INET" }).first else { return nil }
        return interface.address
    }
}
