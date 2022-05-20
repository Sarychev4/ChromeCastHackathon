//
//  YouTubeCell.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 17.05.2022.
//

import UIKit

class YouTubeCell: UITableViewCell {

    @IBOutlet weak var sectionNameView: UIView!
    @IBOutlet weak var sectionNameLabel: UILabel!

    @IBOutlet weak var backgroundShadow: DropShadowView!
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var videoImage: UIImageView!
    @IBOutlet weak var videoDescLabel: UILabel!
    @IBOutlet weak var channelNameLabel: UILabel!
    
    @IBOutlet weak var playPauseInteractiveView: InteractiveView!
    @IBOutlet weak var playButtonIcon: UIImageView!
    var didPlayTap: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        
        backgroundShadow.layer.cornerRadius = 20
        imageContainerView.layer.cornerRadius = 20
        imageContainerView.clipsToBounds = true
        
        playPauseInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.didPlayTap?()
        }
    }
    
    
}
