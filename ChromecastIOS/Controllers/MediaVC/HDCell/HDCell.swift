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
    
    private let imageManager = PHCachingImageManager()
    private var lastImageRequest: PHImageRequestID?
    
    var prevAction: (() -> ())?
    var nextAction: (() -> ())?
    var playOrPauseAction: (() -> ())?
    var rewindAction: ((Double) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func setupCell(with asset: PHAsset, state: VideoPlayerManager.State, size: CGSize, isVideoOfCellPlaying: Bool) {
       
        photoWidthConstraint.constant = size.width
        photoHeightConstraint.constant = size.height
        clipsToBounds = true
        photoImageView?.contentMode = .scaleAspectFit
        photoImageView?.image = nil
        
        if let lastImageRequest = lastImageRequest {
            imageManager.cancelImageRequest(lastImageRequest)
        }
        
        lastImageRequest = imageManager.image(for: asset,
                                size: PHImageManagerMaximumSize,
                                contentMode: .aspectFit,
                                progressHandler: {progress in
        }, completion: { [weak self] image in
            guard let self = self, let image = image else { return }
            self.photoImageView?.image = image
        })
       
        if asset.mediaType == .image {
            playerButtonsContainer.isHidden = true
        } else {
            playerButtonsContainer.isHidden = false
            setupVideo(with: asset, state: state, isVideoOfCellPlaying: isVideoOfCellPlaying )
        }

    }
    
    private func setupVideo(with asset: PHAsset, state: VideoPlayerManager.State, isVideoOfCellPlaying: Bool) {
        
        if state.isSameAs(.playing) && isVideoOfCellPlaying == true {
            playVideoInteractiveImageView.image = UIImage(named: "PausePlayerIcon")
        } else {
            playVideoInteractiveImageView.image = UIImage(named: "PlayPlayerIcon")
        }
 
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
    
//    @objc func changeSlider(sender: UISlider) {
//        self.rewindAction?(TimeInterval(sender.value))
//    }

}
