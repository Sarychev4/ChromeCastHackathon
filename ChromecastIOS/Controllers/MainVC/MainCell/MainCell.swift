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
    
    var type: MenuButtonType = .media
    var showControllerAction: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentCellView.didTouchAction = {
            self.showControllerAction?()
        }
    }

}
