//
//  TutorialRatingStarsViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 26.04.2022.
//

import UIKit
import Agregator
import StoreKit

class TutorialRatingStarsViewController: BaseViewController {
    
    deinit {
        print(">>> deinit TutorialRatingStarsViewController")
    }
    
    private enum State {
        case waiting, `continue`
    }
    
    @IBOutlet weak var containerForLayersAndThumb: UIView!
    @IBOutlet weak var containerForLayers: UIView!
    
    @IBOutlet weak var unfilledContainer: UIView!
    @IBOutlet weak var unfilledLineView: UIView!
    @IBOutlet weak var unfilledPointsStackView: UIStackView!
    
    @IBOutlet weak var filledContainer: UIView!
    @IBOutlet weak var filledLineView: UIView!
    @IBOutlet weak var filledPointsStackView: UIView!
    
    @IBOutlet weak var thumbView: UIView!
    @IBOutlet weak var thumbImageView: UIImageView!
    
    @IBOutlet weak var ratingContainerView: UIView!
    @IBOutlet weak var ratingContinueInteractiveView: InteractiveView!
    @IBOutlet weak var ratingContinueLabel: DefaultLabel!
    @IBOutlet weak var ratingActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var thankYouContainerView: UIView!
    @IBOutlet weak var thankYouContinueInteractiveView: InteractiveView!
    @IBOutlet weak var thankYouContinueLabel: DefaultLabel!
    @IBOutlet weak var thankYouActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var thankYouContainerLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var thankYouContainerRightConstraint: NSLayoutConstraint!
    
    private var state: TutorialRatingStarsViewController.State = .waiting
    private var ratingScore = 5
    private var step: Double = 0
    private var isAnimating: Bool = false
    var movePageControl: (() -> ())?
    
    var didFinishAction: (() -> ())?
    var source: String!
    var nameForEvents: String {
        return "Rating stars screen"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AgregatorLogger.shared.log(eventName: "Tutorial_shown",
                                   parameters: ["Tutorial Step": nameForEvents, "Source": source])
        
        ratingContinueInteractiveView.cornerRadius = 8 * SizeFactor
        ratingContinueInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            if self.ratingScore < 5 {
                self.state = .continue
            }
            switch self.state {
            case .waiting:
                self.ratingContinueInteractiveView.isUserInteractionEnabled = false
                self.ratingContinueInteractiveView.layer.opacity = 0.33
                
                DispatchQueue.main.asyncAfter(deadline: .now(), execute: { [weak self] in
                    guard let _ = self else { return }
                    AgregatorLogger.shared.log(eventName: "Rating alert shown", parameters: ["Source": "Rate stars"])
                    SKStoreReviewController.requestReview()
                })
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    guard let self = self else { return }
                    UIView.animate(withDuration: 0.2, animations: {
                        self.ratingContinueInteractiveView.isUserInteractionEnabled = true
                        self.ratingContinueInteractiveView.layer.opacity = 1
                    }) { [weak self] (success) in
                        guard let self = self else { return }
                        self.state = .continue
                        self.isAnimating = false
                    }
                }
            case .continue:
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                    self.ratingContainerView.frame.origin.x = -UIScreen.main.bounds.size.width
                    self.thankYouContainerView.frame.origin.x = 0
                    self.movePageControl?()
                }, completion: { (finished) in

                })
            }
        }
        
        thankYouContinueInteractiveView.cornerRadius = 8 * SizeFactor
        thankYouContinueInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            AgregatorLogger.shared.log(eventName: "thank_you", parameters: ["Value": "continue"])
            self.didFinishAction?()
        }
        
        hideThankYouContainer()
        setupRatingStarsSlider()
        
        /*
         */
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForegroundAction),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
        
        /*
         */
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        thumbView.cornerRadius = thumbView.frame.width / 2 * SizeFactor
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        step = containerForLayers.layer.frame.size.width / 4
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func willEnterForegroundAction() {
        AgregatorLogger.shared.log(eventName: "Tutorial_shown",
                                   parameters: ["Tutorial Step": nameForEvents, "Source": "Launch"])
    }
    
    private func hideThankYouContainer() {
        thankYouContainerLeftConstraint.constant = UIScreen.main.bounds.width
        thankYouContainerRightConstraint.constant += UIScreen.main.bounds.width
    }
    
    private func setupRatingStarsSlider() {
        thumbView.isUserInteractionEnabled = true
        containerForLayers.isUserInteractionEnabled = true
        filledContainer.clipsToBounds = true
        
        let drag = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        thumbView.addGestureRecognizer(drag)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        containerForLayers.addGestureRecognizer(tap)
    }
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        guard let sender = sender else { return }
        let currentLocation = sender.location(in: containerForLayers).x
        let containerForLayersOriginX = containerForLayers.frame.origin.x
        
        print(">>> Current Location \(currentLocation)")
        print(">>> Thumb Center \(thumbView.center.x)")
        if currentLocation < self.step / 2 {
            filledContainer.layer.frame.size.width = 0
            thumbView.center.x = containerForLayersOriginX + 8
            thumbImageView.image = UIImage(named: "selectedStepper1")
            ratingScore = 1
        } else if currentLocation >= self.step / 2 && currentLocation < self.step * 1.5 {
            filledContainer.layer.frame.size.width = self.step
            thumbView.center.x = containerForLayersOriginX + self.step
            thumbImageView.image = UIImage(named: "selectedStepper2")
            ratingScore = 2
        } else if currentLocation >= self.step * 1.5 && currentLocation < self.step * 2.5 {
            filledContainer.layer.frame.size.width = self.step * 2
            thumbView.center.x = containerForLayersOriginX + self.step * 2
            thumbImageView.image = UIImage(named: "selectedStepper3")
            ratingScore = 3
        } else if currentLocation >= self.step * 2.5 && currentLocation < self.step * 3.5 {
            filledContainer.layer.frame.size.width = self.step * 3
            thumbImageView.image = UIImage(named: "selectedStepper4")
            thumbView.center.x = containerForLayersOriginX + self.step * 3
            ratingScore = 4
        } else if currentLocation >= self.step * 3.5{
            filledContainer.layer.frame.size.width = self.step * 4
            thumbView.center.x = containerForLayersOriginX + self.step * 4 - 8
            thumbImageView.image = UIImage(named: "selectedStepper5")
            ratingScore = 5
        }
    }
    
    @objc private func handleGesture(_ gestureRecognizer: UIPanGestureRecognizer){
        let currentLocation = gestureRecognizer.location(in: containerForLayers).x
        let containerForLayersOriginX = containerForLayers.frame.origin.x
        
        switch gestureRecognizer.state {
        case .began:
            print(">>> BEGAN")
        case .changed:
            
            print(">>> Location \(gestureRecognizer.location(in: containerForLayers).x)")
            if currentLocation >= 8  && currentLocation <= containerForLayers.layer.frame.size.width - 8 {
                filledContainer.layer.frame.size.width = currentLocation
                thumbView.center.x = containerForLayersOriginX + currentLocation
            }
            
            if currentLocation < self.step / 2 {
                thumbImageView.image = UIImage(named: "selectedStepper1")
            } else if currentLocation >= self.step / 2 && currentLocation < self.step * 1.5 {
                thumbImageView.image = UIImage(named: "selectedStepper2")
            } else if currentLocation >= self.step * 1.5 && currentLocation < self.step * 2.5 {
                thumbImageView.image = UIImage(named: "selectedStepper3")
            } else if currentLocation >= self.step * 2.5 && currentLocation < self.step * 3.5 {
                thumbImageView.image = UIImage(named: "selectedStepper4")
            } else if currentLocation >= self.step * 3.5{
                thumbImageView.image = UIImage(named: "selectedStepper5")
            }
            
            print(">>> FilledContainer Width \(filledContainer.layer.frame.size.width)")
        case .cancelled, .ended:
            print(">>> End")
            print(">>> Location \(gestureRecognizer.location(in: containerForLayers))")
            
            if currentLocation < self.step / 2 {
                filledContainer.layer.frame.size.width = 0
                thumbView.center.x = containerForLayersOriginX + 8
                ratingScore = 1
            } else if currentLocation >= self.step / 2 && currentLocation < self.step * 1.5 {
                filledContainer.layer.frame.size.width = self.step
                thumbView.center.x = containerForLayersOriginX + self.step
                ratingScore = 2
            } else if currentLocation >= self.step * 1.5 && currentLocation < self.step * 2.5 {
                filledContainer.layer.frame.size.width = self.step * 2
                thumbView.center.x = containerForLayersOriginX + self.step * 2
                ratingScore = 3
            } else if currentLocation >= self.step * 2.5 && currentLocation < self.step * 3.5 {
                filledContainer.layer.frame.size.width = self.step * 3
                thumbView.center.x = containerForLayersOriginX + self.step * 3
                ratingScore = 4
            } else if currentLocation >= self.step * 3.5{
                filledContainer.layer.frame.size.width = self.step * 4
                thumbView.center.x = containerForLayersOriginX + self.step * 4 - 8
                ratingScore = 5
            }
        default:
            break
        }
    }
    
}
