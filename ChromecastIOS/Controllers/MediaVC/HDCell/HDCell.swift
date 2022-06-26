//
//  HDCell.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 22.04.2022.
//

import UIKit
import Photos
import Agregator
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
    private var lowQualityImageRequest: PHImageRequestID?
    private var highQualityImageRequest: PHImageRequestID?
    
    var prevAction: (() -> ())?
    var nextAction: (() -> ())?
    var playOrPauseAction: (() -> ())?
    var rewindAction: ((Double) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func setupCell(with asset: PHAsset, state: VideoPlayerManager.State, size: CGSize, isVideoOfCellPlaying: Bool, isCurrentDisplayingCell: Bool) {
       
        photoWidthConstraint.constant = size.width
        photoHeightConstraint.constant = size.height
        clipsToBounds = true
        photoImageView?.contentMode = .scaleAspectFit
        if isCurrentDisplayingCell == false {
            photoImageView?.image = nil
        }
        
        if let lowQualityImageRequest = lowQualityImageRequest {
            imageManager.cancelImageRequest(lowQualityImageRequest)
        }
        
        if let highQualityImageRequest = highQualityImageRequest {
            imageManager.cancelImageRequest(highQualityImageRequest)
        }
        
        if asset.mediaType == .image {
            playerButtonsContainer.isHidden = true
            tryHighQuality(for: asset, onComplete: { [weak self] success in
                guard let self = self, success == false else { return }
                self.setLowQuality(for: asset)
            })
        } else {
            setLowQuality(for: asset)
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
    
    private func tryHighQuality(for asset: PHAsset, onComplete: ClosureBool?) {
        highQualityImageRequest = imageManager.image(
            for: asset,
            size: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            isNetworkAccessAllowed: false,
            progressHandler: nil,
            completion: { [weak self] image in
                guard let self = self, let image = image else {
                    onComplete?(false)
                    return
                }
                self.photoImageView?.image = image
                onComplete?(true)
            })
    }
    
    private func setLowQuality(for asset: PHAsset) {
        lowQualityImageRequest = imageManager.requestImage(
            for: asset,
            targetSize: CGSize(width: 300, height: 300),
            contentMode: .aspectFit,
            options: nil,
            resultHandler: { [weak self] image, info in
                let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                guard isDegraded == false, let self = self else { return }
                self.photoImageView?.image = image
            })
    }
    
//    @objc func changeSlider(sender: UISlider) {
//        self.rewindAction?(TimeInterval(sender.value))
//    }

}
