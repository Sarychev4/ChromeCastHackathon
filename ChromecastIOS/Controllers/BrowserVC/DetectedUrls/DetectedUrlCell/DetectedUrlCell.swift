//
//  DetectedUrlCell.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 13.05.2022.
//


import UIKit

class DetectedUrlCell: UITableViewCell {
    @IBOutlet weak var videoImage: UIImageView!
    @IBOutlet weak var containerInteractiveView: InteractiveView!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var videoFormatLabel: UILabel!
    
    var didTapped: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        containerInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else {return}
            self.didTapped?()
        }
    }

}

