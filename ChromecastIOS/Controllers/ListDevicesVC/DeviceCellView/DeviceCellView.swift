//
//  DeviceCellView.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 26.04.2022.
//

import UIKit

class DeviceCellView: UIView {

    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var containerDropShadowView: DropShadowView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var containerInteractiveView: InteractiveView!
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @discardableResult func loadNib() -> UIView {
        guard let view = Bundle.main.loadNibNamed("DeviceCellView", owner: self, options: nil)?.first as? UIView else { return UIView() }
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.frame = bounds
        containerDropShadowView.layer.cornerRadius = 15
        addSubview(view)
        return view
    }
}
