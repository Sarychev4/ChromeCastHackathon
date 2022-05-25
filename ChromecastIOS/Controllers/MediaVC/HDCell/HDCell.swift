//
//  HDCell.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 22.04.2022.
//

import UIKit
import Photos
import Player

class HDCell: UICollectionViewCell {
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var photoWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var playerButtonsContainer: UIStackView!
    @IBOutlet weak var previousVideoInteractiveImageView: InteractiveImageView!
    @IBOutlet weak var playVideoInteractiveImageView: InteractiveImageView!
    @IBOutlet weak var nextVideoInteractiveImageView: InteractiveImageView!
    
    
    @IBOutlet weak var progressContainerView: UIView!
    @IBOutlet weak var currentPlayTimeLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    @IBOutlet weak var progressView: UISlider!
    
    var prevAction: (() -> ())?
    var nextAction: (() -> ())?
    var playOrPauseAction: (() -> ())?
    var rewindAction: ((Double) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setup(with asset: PHAsset, state: VideoPlayerManager.State, currentTime: Double) {
       
        let videoDuration = asset.duration
        let currentTimeRoundedInt = Int(currentTime / 1000)
        let currentTimeDouble = currentTime / 1000
        progressView.maximumValue = Float(videoDuration)
        progressView.minimumValue = Float(0)
        progressView.value = Float(videoDuration - currentTimeDouble) > 1 ? Float(currentTimeDouble) : Float(videoDuration)
        currentPlayTimeLabel.text = currentTimeRoundedInt.durationText
        remainingTimeLabel.text = "\(videoDuration.durationText)"
        
        print(">>> ***")
        print(">>> VIDEODUrAtiON\(videoDuration)")
        print(">>> CURRENT TIME \(currentTime)")
        print(">>> ***")
        if state.isSameAs(.playing) {
            playVideoInteractiveImageView.image = UIImage(named: "PausePlayerIcon")
        } else {
            playVideoInteractiveImageView.image = UIImage(named: "PlayPlayerIcon")
        }
        
        /*
         */
        
        progressView.addTarget(self, action: #selector(changeSlider), for: .valueChanged)
        /*
         */
        
        previousVideoInteractiveImageView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.prevAction?()
        }
        
        nextVideoInteractiveImageView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.nextAction?()
        }
        
        playVideoInteractiveImageView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.playOrPauseAction?()
        }
        
    }
    
    @objc func changeSlider(sender: UISlider) {
        self.rewindAction?(TimeInterval(sender.value))
    }

}
