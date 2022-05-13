//
//  DetectedUrl.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 13.05.2022.
//

import Foundation
import Realm
import RealmSwift
import UIKit

class DetectedUrl: Object {
    @Persisted(primaryKey: true) var url: String = ""
    @Persisted var size: String = ""
    @Persisted var format: String = ""
    
}
