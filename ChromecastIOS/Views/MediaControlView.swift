//
//  MediaControlView.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 20.05.2022.
//

import UIKit

class MediaControlView: DefaultView {
    
    @IBOutlet weak var prevInteractiveView: InteractiveView!
    @IBOutlet weak var forwardInteractiveView: InteractiveView!
    @IBOutlet weak var playPauseInteractiveView: InteractiveView!
    @IBOutlet weak var playButtonIcon: UIImageView!
    @IBOutlet weak var currentPlayTimeLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    @IBOutlet weak var progressView: CustomSlider!
}
