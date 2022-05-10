//
//  CommentView.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 10.05.2022.
//

import UIKit

class CommentView: DefaultView {

    /*
     MARK: -
     */
    
    @IBOutlet var starsImageView: UIImageView!
    @IBOutlet var nameLabel: DefaultLabel!
    @IBOutlet var textLabel: DefaultLabel!
    
    /*
     MARK: -
     */
    
    var name: String! {
        didSet {
            nameLabel.text = name
        }
    }
    var text: String! {
        didSet {
            textLabel.text = text
        }
    }
    var starsImage: UIImage! {
        didSet {
            starsImageView.image = starsImage
        }
    }
    
    /*
     MARK: -
     */
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}
