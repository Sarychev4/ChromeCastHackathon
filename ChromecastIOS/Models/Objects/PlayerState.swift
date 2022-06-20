//
//  PlayerState.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 18.06.2022.
//

import Foundation
import RealmSwift

enum PlaybackState {
    case playing
    case paused
    case stopped
}

class PlayerState: Object {
    @objc @Persisted var state: PlayerCurrentState = .idle
}

@objc enum PlayerCurrentState: Int, PersistableEnum {
    case unknown = 0, idle = 1, playing = 2, paused = 3, buffering = 4,  loading = 5
}
