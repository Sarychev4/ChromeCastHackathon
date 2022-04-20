//
//  DefaultView.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 19.04.2022.
//

import UIKit

open class DefaultView: UIView {

    /*
     MARK: - Outlets
     */
    
    @IBOutlet var constraintsToScale: [NSLayoutConstraint]?
    @IBOutlet var stackViewsToScale: [UIStackView]?
    
    @IBInspectable open var isAutomaticalyResizeEnabled: Bool = false
    
    /*
     MARK: -
     */
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        awakeFromNib()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        
        if isAutomaticalyResizeEnabled == true {
            resizeAllConstraints(for: self)
            resizeAllStackViews(for: self)
        } else {
            if let constraints = constraintsToScale {
                for constraint in constraints {
                    constraint.constant = round(constraint.constant * SizeFactor)
                }
            }
            
            if let stackViews = stackViewsToScale {
                for stackView in stackViews {
                    stackView.spacing = round(stackView.spacing * SizeFactor)
                }
            }
        }
    }
    
    func resizeAllConstraints(for view: UIView) {
        
        for constraint in view.constraints {
            constraint.constant = round(constraint.constant * SizeFactor)
        }
        
        for subview in view.subviews {
            resizeAllConstraints(for: subview)
        }
    }
    
    func resizeAllStackViews(for view: UIView) {
        
        for subview in view.subviews {
            if let stackView = subview as? UIStackView {
                stackView.spacing = round(stackView.spacing * SizeFactor)
            }
            
            resizeAllStackViews(for: subview)
        }
        
    }

}
