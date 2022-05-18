//
//  IPTVPlayListCell.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 11.05.2022.
//

import UIKit

class IPTVPlayListCell: UITableViewCell {

    @IBOutlet weak var sectionNameView: UIView!
    @IBOutlet weak var sectionNameLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var backgroundShadow: DropShadowView!
    @IBOutlet weak var logoContainerView: UIView!
    @IBOutlet weak var logoLabel: UILabel!
    @IBOutlet weak var playlistNameLabel: DefaultLabel!
    @IBOutlet weak var playlistInfoLabel: DefaultLabel!
    
    var didEditAction: Closure?
    var didTouchAction: Closure?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
    }
    
    func setup(with playlist: PlaylistM3U8) {
        editButton.isHidden = !playlist.isUserStream
        if playlist.id.isEmpty == false {
            logoLabel.text = "\(playlist.name.first!)"
        }
        playlistNameLabel.text = playlist.name
        playlistInfoLabel.text = "\(playlist.streams.count) Channels"
    }
    
    @IBAction func contentClicked(_ sender: Any) {
        didTouchAction?()
    }
    
    @IBAction func editClicked(_ sender: Any) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        didEditAction?()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
