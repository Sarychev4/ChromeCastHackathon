//
//  DeviceObject.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 06.05.2022.
//

import Foundation
import RealmSwift

class DeviceObject: Object {
    @Persisted(primaryKey: true) var deviceID: String = ""
    @Persisted var deviceUniqueID: String = ""
    @Persisted var friendlyName: String = ""
    @Persisted var modelName: String = ""
}
