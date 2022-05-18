//
//  IPTVStreamCell.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 11.05.2022.
//

import UIKit
import Kingfisher

class IPTVStreamCell: UITableViewCell {
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var logoLabel: UILabel!
    @IBOutlet weak var playlistNameLabel: DefaultLabel!
    @IBOutlet weak var playlistInfoLabel: DefaultLabel!
    
    var didTouchAction: Closure?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func contentClicked(_ sender: Any) {
        print("GGGGGG")
        didTouchAction?()
    }
    
    func setup(with stream: IPTVStream) {
        logoLabel.text = ""
        logoImageView.backgroundColor = .clear
        if let url = URL(string: stream.logo) {
            logoImageView.kf.setImage(with: url, options: [.transition(.fade(0.3))])
        } else if stream.name.isEmpty == false {
            logoImageView.backgroundColor = UIColor(named: "AppleBlue")
            logoLabel.text = "\(stream.name.first!)"
        }
        playlistInfoLabel.text = stream.url
        playlistNameLabel.text = stream.name
    }
    
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
