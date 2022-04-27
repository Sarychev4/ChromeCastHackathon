//
//  InteractiveLabel.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 27.04.2022.
//

import UIKit

open class InteractiveLabel: DefaultLabel {

    /*
     MARK: -
     */
    
    open var opacityFactor: Float = 0.5
    open var isHighlightingEnabled: Bool = true
    open var didTouchAction: (() -> ())?
    
    var _isEnabled: Bool = true
    override open var isEnabled: Bool {
        get {
            return _isEnabled
        }
        set {
            _isEnabled = isEnabled
            
            isUserInteractionEnabled = isEnabled
            layer.opacity = isEnabled ? 1 : defaultOpacity * opacityFactor
        }
    }
    
    @IBInspectable open var isHapticEnabled: Bool = true
    
    /*
     MARK: -
     */
    
    private let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .light)
    private var defaultOpacity: Float = 1
    
    /*
     MARK: -
     */
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        awakeFromNib()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        isUserInteractionEnabled = true
    }
    
    /*
     MARK: -
     */
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if isHighlightingEnabled == true {
            defaultOpacity = layer.opacity
            layer.opacity = defaultOpacity * opacityFactor
        }
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        restoreState()
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        restoreState()
        
        if let touch = touches.first {
            let location = touch.location(in: self)
            if bounds.contains(location) {
                if isHapticEnabled {
                    impactFeedbackgenerator.impactOccurred()
                }
                didTouchAction?()
            }
        }
    }
    
    func restoreState() {
        layer.add(CATransition(), forKey: nil)
        layer.opacity = defaultOpacity
    }

}
