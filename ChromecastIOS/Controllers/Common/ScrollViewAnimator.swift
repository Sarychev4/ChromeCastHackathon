//
//  ScrollViewAnimator.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 12.05.2022.
//

import Foundation
import UIKit

class ScrollViewAnimator {
    
    var minAnchor:CGFloat = 0 //210
    var maxAnchor:CGFloat = 0 //310
    var lastContentOffset: CGFloat = 0
    
    var animator: UIViewPropertyAnimator?
    
    init(minAnchor: Int, maxAnchor: Int, animator: UIViewPropertyAnimator) {
        self.minAnchor = CGFloat(minAnchor)
        self.maxAnchor = CGFloat(maxAnchor)
        self.animator = animator
    }

    func handleAnimation(with currentPosition: CGFloat) {
        let progress = min(max(0, (currentPosition - minAnchor) / (maxAnchor - minAnchor)), 1)
        animator?.fractionComplete = progress
    }
}
