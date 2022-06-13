//
//  HDCell.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 22.04.2022.
//

import UIKit
import Photos
//import Player

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
    
    private let imageManager = PHCachingImageManager()
    private var lastImageRequest: PHImageRequestID?
    
    var prevAction: (() -> ())?
    var nextAction: (() -> ())?
    var playOrPauseAction: (() -> ())?
    var rewindAction: ((Double) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func setupCell(with asset: PHAsset, state: VideoPlayerManager.State, currentTime: Double, size: CGSize) {
       
        photoWidthConstraint.constant = size.width
        photoHeightConstraint.constant = size.height
        clipsToBounds = true
        photoImageView?.contentMode = .scaleAspectFit
        
        if let lastImageRequest = lastImageRequest {
            imageManager.cancelImageRequest(lastImageRequest)
            photoImageView?.image = nil
        }
        
        lastImageRequest = imageManager.image(for: asset,
                                size: PHImageManagerMaximumSize,
                                contentMode: .aspectFit,
                                progressHandler: {progress in
        }, completion: { [weak self] image in
            guard let self = self, let image = image else { return }
            self.photoImageView?.image = image
        })
//        image(for: asset, size: CGSize(width: size.width, height: size.height)) { (image, needd) in
//            self.photoImageView?.image = image
//        }
       
        if asset.mediaType == .image {
            playerButtonsContainer.isHidden = true
            progressContainerView.isHidden = true
        } else {
            playerButtonsContainer.isHidden = false
            progressContainerView.isHidden = false
            setupVideo(with: asset, state: state, currentTime: currentTime)
        }

    }
    
    private func setupVideo(with asset: PHAsset, state: VideoPlayerManager.State, currentTime: Double) {
        
        let videoDuration = asset.duration
        let currentTimeDouble = currentTime
        
        progressView.maximumValue = Float(videoDuration)
        progressView.minimumValue = Float(0)
        progressView.value = Float(videoDuration - currentTimeDouble) > 1 ? Float(currentTimeDouble) : Float(videoDuration)
        
        currentPlayTimeLabel.text = currentTimeDouble.durationText
        remainingTimeLabel.text = "\(videoDuration.durationText)"

        if state.isSameAs(.playing) {
            playVideoInteractiveImageView.image = UIImage(named: "PausePlayerIcon")
        } else {
            playVideoInteractiveImageView.image = UIImage(named: "PlayPlayerIcon")
        }

        
        progressView.addTarget(self, action: #selector(changeSlider), for: .valueChanged)
 
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
