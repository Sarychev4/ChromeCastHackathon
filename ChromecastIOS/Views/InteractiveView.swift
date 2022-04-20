//
//  InteractiveView.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 19.04.2022.
//

import UIKit

open class InteractiveView: DefaultView {
    
    /*
     MARK: -
     */
    
    open var opacityFactor: Float = 0.5
    open var didTouchAction: (() -> ())?
    open var isEnabled: Bool = true {
        didSet {
            isUserInteractionEnabled = isEnabled
            
            if isEnabled == true {
                if let value = enabledBackgroundColor {
                    backgroundColor = value
                } else if let value = defaultBackgroundColor {
                    backgroundColor = value
                } else {
                    layer.opacity = 1
                }
            } else {
                if let value = disabledBackgroundColor {
                    defaultBackgroundColor = backgroundColor
                    backgroundColor = value
                } else {
                    layer.opacity = defaultOpacity * opacityFactor
                }
            }
        }
    }
    
    @IBInspectable open var isHapticEnabled: Bool = true
    @IBInspectable open var enabledBackgroundColor: UIColor? = .clear
    @IBInspectable open var disabledBackgroundColor: UIColor? = .clear
    @IBInspectable open var isHighlightingEnabled: Bool = true
    
    private var defaultOpacity: Float = 1
    private var defaultBackgroundColor: UIColor? = nil
    private var isInteracting: Bool = false
    
    /*
     MARK: -
     */
    
    private let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .light)
    
    /*
     MARK: -
     */
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard isHighlightingEnabled == true && isInteracting == false else {
            return
        }
        isInteracting = true
        defaultOpacity = layer.opacity
        layer.opacity = defaultOpacity * opacityFactor
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
    
    open func restoreState() {
        isInteracting = false
        layer.add(CATransition(), forKey: nil)
        layer.opacity = defaultOpacity
    }
    
}
