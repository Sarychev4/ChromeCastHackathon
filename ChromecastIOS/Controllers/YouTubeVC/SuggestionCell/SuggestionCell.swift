//
//  SuggestionCell.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 17.05.2022.
//

import UIKit

class SuggestionCell: UITableViewCell {

    @IBOutlet weak var suggestionLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
