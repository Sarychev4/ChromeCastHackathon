//
//  ConnectViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 25.04.2022.
//

import UIKit

class TutorialConnectViewController: BaseViewController {
    
    @IBOutlet weak var continueInteractiveView: InteractiveView!
    @IBOutlet weak var continueLabel: DefaultLabel!
    
    @IBOutlet weak var continueInteractiveViewCopy: UIView!
    @IBOutlet weak var continueLabelCopy: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var progressWidthConstraint: NSLayoutConstraint!
    
    var didFinishAction: (() -> ())?
    
    private var isAnimating: Bool = false
    private var progressTimer: Timer?
    private var currentProgress: Int = 0
    
    var temp = false
    override func viewDidLoad() {
        super.viewDidLoad()

        continueInteractiveView.cornerRadius = 8 * SizeFactor
        continueInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.didFinishAction?()
        }    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startProcessingAnimation()
    }
    //MARK: - Process Animation
    private func startProcessingAnimation() {
        guard currentProgress < 100 else { return }
        
        if temp ==  true {
            showLongAnimation { [weak self] in
                guard let self = self else { return }
                
            }
        } else {
            showShortAnimation { [weak self] in
                guard let self = self else { return }
                
            }
        }
    }
    
    private func showShortAnimation(onComplete: @escaping () -> ()) {
        animateWithRandomDuration(in: 1.5..<2.5, toPercent: 0.45) { [weak self] in
            self?.animateWithRandomDuration(in: 0.5..<1, toPercent: 1) {
                onComplete()
            }
        }
    }
    
    private func showLongAnimation(onComplete: @escaping () -> ()) {
        animateWithRandomDuration(in: 1..<2, toPercent: 0.35) { [weak self] in
            self?.animateWithRandomDuration(in: 1..<2, toPercent: 0.45) { [weak self] in
                self?.animateWithRandomDuration(in: 2..<4, toPercent: 0.7) { [weak self] in
                    self?.animateWithRandomDuration(in: 1..<2, toPercent: 1) {
                        onComplete()
                    }
                }
            }
        }
    }
    
    private func animateWithRandomDuration(in range: Range<Double>, toPercent: Double, onComplete: @escaping () -> ()) {
        let maxWidth = UIScreen.main.bounds.width - 80
        let duration = Double.random(in: range)
        let ticksCount = max(1, toPercent * 100 - Double(currentProgress)) //Мы ниже делим на ticksCount, поэтому нельзя чтобы было 0
        
        startProgressTimer(withInterval: duration / ticksCount)
        progressWidthConstraint.constant = maxWidth * toPercent
        
        UIView.animate(withDuration: duration, delay: 0.0) { [weak self] in
            guard let self = self else { return }
            self.view.layoutIfNeeded()
        } completion: { [weak self] success in
            guard let self = self else { return }
            if success {
                onComplete()
            } else {
                self.stopProgressTimer()
            }
        }
    }
    
    private func startProgressTimer(withInterval interval: Double) {
        stopProgressTimer()
        
        guard currentProgress < 100 else { print(">>> error!"); return }
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { [weak self] (timer) in
            guard let self = self else { return }
            self.currentProgress = min(100, self.currentProgress + 1) //Больше 100% прогресс не надо нам
            let text = "\(self.currentProgress)%"
            self.continueLabel.text = text
            self.continueLabelCopy.text = text
        })
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

}
