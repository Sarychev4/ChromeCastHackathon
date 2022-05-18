//
//  HDCell.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 22.04.2022.
//

import UIKit

class HDCell: UICollectionViewCell {
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var photoWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var playerButtonsContainer: UIStackView!
    @IBOutlet weak var previousVideoInteractiveImageView: InteractiveImageView!
    @IBOutlet weak var playVideoInteractiveImageView: InteractiveImageView!
    @IBOutlet weak var nextVideoInteractiveImageView: InteractiveImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
