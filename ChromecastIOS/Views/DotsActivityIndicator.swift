//
//  DotsActivityIndicator.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 27.04.2022.
//

import Foundation
import UIKit

open class DotsActivityIndicator: UIView {
    
    fileprivate var stopped: Bool = false
    
    /// true if the loader should be hidden when it is not animating, default = true
    open var hidesWhenStopped: Bool = true
    
    /// The color of the loader view
    
    var colors: [UIColor]! {
        didSet {
            for (index, sublayer) in layer.sublayers!.enumerated() {
                guard index < colors.count else {
                    return
                }
                let newSublayer = sublayer
                newSublayer.backgroundColor = colors[index].cgColor
            }
            
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        setupAnimation(layer, size: frame.size, color: tintColor)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupAnimation(layer, size: frame.size, color: tintColor)
    }
    
    /**
     * Start animating the loader view
     */
    open func startAnimating() {
        if !isAnimating() {
            stopped = false
            isHidden = false
            resumeLayers()
        }
    }
    
    /**
     * Stop animating the loader view
     * if hidesWhenStopped = true then the loader will be hidden as well
     */
    open func stopAnimating() {
        if isAnimating() {
            if hidesWhenStopped {
                isHidden = true
            }
            stopped = true
            pauseLayers()
        }
    }
    
    /**
     * returns true if the loader is animating
     */
    open func isAnimating() -> Bool {
        return !stopped
    }
    
    fileprivate func resumeLayers() {
        let pausedTime = layer.timeOffset
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        
        layer.speed = 1.0;
        layer.timeOffset = 0.0;
        layer.beginTime = 0.0;
        layer.beginTime = timeSincePause;
    }
    
    fileprivate func pauseLayers() {
        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0;
        layer.timeOffset = pausedTime;
    }
    
    fileprivate func setupAnimation(_ layer: CALayer, size: CGSize, color: UIColor) {
        let beginTime = CACurrentMediaTime();
        
        let offset: CGFloat = size.width / 8;
        let circleSize: CGFloat = offset * 2;
        
        for i in 0..<3 {
            
            let circleX = CGFloat(i) * 3 * offset
            let circleY = size.height / 2 - circleSize / 2
            
            let circle = CALayer();
            circle.frame = CGRect(x: circleX, y: circleY, width: circleSize, height: circleSize);
            circle.backgroundColor = color.cgColor;
            circle.anchorPoint = CGPoint(x: 0.5, y: 0.5);
            circle.cornerRadius = circle.bounds.height * 0.5;
            circle.transform = CATransform3DMakeScale(0.0, 0.0, 0.0);
            
            let anim = CAKeyframeAnimation(keyPath: "transform");
            anim.isRemovedOnCompletion = false;
            anim.repeatCount = Float.infinity;
            anim.duration = 1.5;
            anim.beginTime = beginTime + CFTimeInterval(0.25 * CGFloat(i));
            anim.keyTimes = [0.0, 0.5, 1.0];
            
            anim.timingFunctions = [
                CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut),
                CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut),
                CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            ];
            
            anim.values = [
                NSValue(caTransform3D: CATransform3DMakeScale(0.0, 0.0, 0.0)),
                NSValue(caTransform3D: CATransform3DMakeScale(1.0, 1.0, 0.0)),
                NSValue(caTransform3D: CATransform3DMakeScale(0.0, 0.0, 0.0))
            ];
            
            layer.addSublayer(circle)
            circle.add(anim, forKey: "anime")
            
            stopAnimating()
        }
    }
}

