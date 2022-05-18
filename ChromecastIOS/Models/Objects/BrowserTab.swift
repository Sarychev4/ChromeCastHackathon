//
//  BrowserTab.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 13.05.2022.
//

import Foundation
import Realm
import RealmSwift
import UIKit

let DefaultTabScreenshot = UIImage(named: "tabscreentemp")!.jpegData(compressionQuality: 0.95)!
let DefaultLocalPage = "file:///Users/sarychev/Library/Developer/CoreSimulator/Devices/D1F0D1CC-1EDD-4FD6-B6FA-99B588F6A693/data/Containers/Bundle/Application/48886EF2-DC4D-4727-988B-40FF447ECDD5/ScreenMirroring.app/Browser%20Start%20Page/Index.html"

class BrowserTab: Object {
    @Persisted(primaryKey: true) var id = ""
    @objc @Persisted var isCurrentTab = false
    @Persisted var link = DefaultLocalPage
    @Persisted var image = DefaultTabScreenshot
    
}

extension BrowserTab {
    static var current: BrowserTab {
        let realm = try! Realm()
        return realm
            .objects(BrowserTab.self)
            .filter("\(#keyPath(BrowserTab.isCurrentTab)) == \(true)")
            .first!
    }
}
