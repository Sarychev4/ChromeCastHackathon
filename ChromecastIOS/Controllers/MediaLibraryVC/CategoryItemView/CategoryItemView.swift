//
//  CategoryItemView.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 28.04.2022.
//

import UIKit

class CategoryItemView: UIView {

    @IBOutlet weak var dropShadowBackgroundView: DropShadowView!
    @IBOutlet weak var containerInteractiveView: InteractiveView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var isSelected: Bool = false {
        didSet {
            dropShadowBackgroundView.backgroundColor = isSelected ? UIColor(hexString: "24282C") : .white
            titleLabel.textColor = isSelected ? .white : UIColor(hexString: "24282C")
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @discardableResult func loadNib() -> UIView {
        guard let view = Bundle.main.loadNibNamed("CategoryItemView", owner: self, options: nil)?.first as? UIView else { return UIView() }
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.frame = bounds
        dropShadowBackgroundView.layer.cornerRadius = 10
        addSubview(view)
        return view
    }
}
