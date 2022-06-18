//
//  PlayerState.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 18.06.2022.
//

import Foundation
import RealmSwift

class PlayerState: Object {
    @Persisted var state: Int = 0
}
