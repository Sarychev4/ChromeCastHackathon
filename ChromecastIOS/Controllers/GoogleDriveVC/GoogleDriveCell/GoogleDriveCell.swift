//
//  GoogleDriveCell.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 14.05.2022.
//

import UIKit

class GoogleDriveCell: UICollectionViewCell {

    @IBOutlet weak var containerView: InteractiveView!
    @IBOutlet weak var fileImageView: UIImageView!
    @IBOutlet weak var fileLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dataSizeLabel: UILabel!
    
    var didChooseCell: Closure?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.didChooseCell?()
        }
        
    }

}
