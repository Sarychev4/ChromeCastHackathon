//
//  Realm+Extension.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 10.05.2022.
//

import RealmSwift
import Foundation

let AppGroupId = "group.chromecast.ios"
let RealmFolderURL = Realm.Configuration.defaultConfiguration.fileURL!.deletingLastPathComponent()
let GroupFolder = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroupId)!

extension Realm {
    static var GroupShared: Realm! {
        let streamConfigURL = GroupFolder.appendingPathComponent("GroupShared.rrealm")
        let config = Realm.Configuration(fileURL: streamConfigURL, schemaVersion: UInt64(Bundle.main.buildVersionNumber)!)
        return try! Realm(configuration: config)
    }
    
    static var IPTV: Realm! {
        let iptvRealm = RealmFolderURL.appendingPathComponent("FreeIPTV.realm")
        let schemaVersion = UInt64(Bundle.main.buildVersionNumber)!
        let config = Realm.Configuration(fileURL: iptvRealm, schemaVersion: schemaVersion)
        return try! Realm(configuration: config)
    }
    
    static var Main: Realm! {
        let fileURL = RealmFolderURL.appendingPathComponent("Configuration.realm")
        let bundleVersion = UInt64(Bundle.main.buildVersionNumber)!
        var realmConfig = Realm.Configuration(fileURL: fileURL, encryptionKey: UserDefaults.realmEncryptionKey, readOnly: false)
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
