//
//  DeviceObject.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 06.05.2022.
//

import Foundation
import RealmSwift

class DeviceObject: Object {
    @objc @Persisted(primaryKey: true) var deviceID: String = ""
    @objc @Persisted var deviceUniqueID: String = ""
    @objc @Persisted var friendlyName: String = ""
    @objc @Persisted var modelName: String = ""
}
