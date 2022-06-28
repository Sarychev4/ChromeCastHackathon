//
//  MainCell.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 20.04.2022.
//

import UIKit

class MainCell: UICollectionViewCell {

    @IBOutlet weak var contentCellView: InteractiveView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    @IBOutlet weak var verticalTextSapceConstraint: NSLayoutConstraint!
    let isVerySmallScreen = UIScreen.main.bounds.size.height <= 568

    var type: MenuButtonType = .media
    var showControllerAction: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if isVerySmallScreen {
            verticalTextSapceConstraint.constant = 9
            titleLabel.font = subtitleLabel.font.withSize(15)
            subtitleLabel.font = subtitleLabel.font.withSize(10)
        }
        contentCellView.didTouchAction = {
            self.showControllerAction?()
        }
    }

}
