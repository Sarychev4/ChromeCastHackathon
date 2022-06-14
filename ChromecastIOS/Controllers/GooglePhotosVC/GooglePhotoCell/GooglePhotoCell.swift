//
//  GooglePhotoCell.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 02.06.2022.
//

import UIKit
import Kingfisher
import GPhotos

class GooglePhotoCell: UICollectionViewCell {

    @IBOutlet weak var containerView: InteractiveView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var itemInfoView: UIView!
    
    var didChooseCell: Closure?
    
    var image: UIImage? {
        didSet {
            previewImageView.image = image
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.cornerRadius = 10
        containerView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.didChooseCell?()
        }
    }
    
    func setup(mimeType: String?, thumbnailLinkString: String?, metaData: MediaMetadata?) {
        guard let imageUrlString = thumbnailLinkString else { return }
        guard let imageUrl:URL = URL(string: imageUrlString) else { return }
        self.previewImageView.kf.setImage(with: imageUrl, options: [.transition(.fade(0.3))])
        
        guard let metaData = metaData else { return }
        if let _ = metaData.video {
            itemInfoView.isHidden = false
        } else {
            itemInfoView.isHidden = true
        }
    }

}
