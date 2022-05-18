//
//  WebsiteCell.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 21.04.2022.
//

import UIKit

class WebsiteCell: UICollectionViewCell {

    @IBOutlet weak var screenImage: UIImageView!
    @IBOutlet weak var linkAddressField: UILabel!
    @IBOutlet weak var cellInteractiveView: InteractiveView!
    @IBOutlet weak var dropShadow: DropShadowView!
    @IBOutlet weak var closeTabInteractiveView: InteractiveView!
    
    var didCloseTabTap: (() -> ())?
    var didChooseTabTap: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        dropShadow.cornerRadius = DefaultCornerRadius
        screenImage.layer.cornerRadius = DefaultCornerRadius
        closeTabInteractiveView.cornerRadius = closeTabInteractiveView.frame.width/2
       
        closeTabInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.didCloseTabTap?()
        }
        
        
        cellInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.didChooseTabTap?()
            
        }
    }

}
