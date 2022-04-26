//
//  TutorialRatingStarsViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 26.04.2022.
//

import UIKit

class TutorialRatingStarsViewController: BaseViewController {
    
    
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
    
    @IBOutlet weak var continueInteractiveView: InteractiveView!
    @IBOutlet weak var continueLabel: DefaultLabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var ratingScore = 5
    private var step: Double = 0
    var didFinishAction: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        continueInteractiveView.cornerRadius = 8 * SizeFactor
        continueInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.didFinishAction?()
        }
        
        setupRatingStarsSlider()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        thumbView.cornerRadius = thumbView.frame.width / 2 * SizeFactor
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        step = containerForLayers.layer.frame.size.width / 4
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
