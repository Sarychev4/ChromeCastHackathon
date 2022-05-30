//
//  GoogleDriveCell.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 14.05.2022.
//

import UIKit
import Kingfisher

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
    
    func setup(name: String?, date: String?, fileSize: NSNumber?, mimeType: String?, thumbnailLinkString: String?) {
        
        guard let name = name, let date = date, let mimeType = mimeType else {
            return
        }
        self.fileLabel.text = name
        self.dateLabel.text = date
        
        if let fileSize = fileSize {
            self.dataSizeLabel.text = ByteCountFormatter.string(fromByteCount: Int64(truncating: fileSize), countStyle: .memory)
        } else {
            self.dataSizeLabel.isHidden = true
        }
        
        if mimeType == "application/vnd.google-apps.folder" {
            self.fileImageView.image = UIImage(named: "folderIcon")!
        } else if mimeType == "image/jpeg" || mimeType == "video/mp4" || mimeType == "image/png" {
            guard let imageUrlString = thumbnailLinkString else { return }
            guard let imageUrl:URL = URL(string: imageUrlString) else { return }
//            guard let imageData = try? Data(contentsOf: imageUrl) else { return }
//            self.fileImageView.image = UIImage(data: imageData)
            self.fileImageView.kf.setImage(with: imageUrl)
        } else if mimeType == "video/mp4" {
            
        } else {
            self.fileImageView.image = UIImage(named: "documentFileIcon")!
        }
        
    }

}
