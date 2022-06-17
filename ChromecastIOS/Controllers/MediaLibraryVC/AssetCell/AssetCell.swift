//
//  MediaItemCollectionViewCell.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 28.04.2022.
//

import UIKit
import Photos

class AssetCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var itemInfoView: UIView!
    @IBOutlet weak var itemDurationLabel: UILabel!
    
    var image: UIImage? {
        didSet {
            previewImageView.image = image
        }
    }
    
    var duration: String? {
        didSet {
            itemDurationLabel.text = duration
        }
    }
    
    var type: PHAssetMediaType = .image {
        didSet {
            itemInfoView.isHidden = type == .image
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.cornerRadius = 10

    }

}
