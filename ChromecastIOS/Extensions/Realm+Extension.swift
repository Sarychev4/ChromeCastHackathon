//
//  Realm+Extension.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 10.05.2022.
//

import RealmSwift
import Foundation

extension Realm {
    static var GroupShared: Realm! {
        let config = Realm.Configuration(fileURL: .GroupRealmFile, schemaVersion: UInt64(Bundle.main.buildVersionNumber)!)
        return try! Realm(configuration: config)
    }
    
    static var IPTV: Realm! {
        let iptvRealm = URL.GroupRealmFile.deletingLastPathComponent().appendingPathComponent("FreeIPTV.realm")
        let schemaVersion = UInt64(Bundle.main.buildVersionNumber)!
        let config = Realm.Configuration(fileURL: iptvRealm, schemaVersion: schemaVersion)
        return try! Realm(configuration: config)
    }
    
    static var Main: Realm! {
        let fileURL = URL.GroupRealmFile.deletingLastPathComponent().appendingPathComponent("Configuration.realm")
        let bundleVersion = UInt64(Bundle.main.buildVersionNumber)!
        var realmConfig = Realm.Configuration(fileURL: fileURL, readOnly: false)
        realmConfig.schemaVersion = bundleVersion
        realmConfig.migrationBlock = { migration, oldSchemaVersion in
            
        }
        realmConfig.shouldCompactOnLaunch = { totalBytes, usedBytes in
            let limitBytes = 100 * 1024 * 1024
            let value = (totalBytes > limitBytes) && (Double(usedBytes) / Double(totalBytes)) < 0.5
            return value
        }
        return try! Realm(configuration: realmConfig)
    }
}
