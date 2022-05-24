//
//  MirrorSettingsViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 04.05.2022.
//

import UIKit

class MirrorSettingsViewController: AFFloatingPanelViewController {

   
    @IBOutlet weak var showHideImageView: UIImageView!
    @IBOutlet weak var qualityContainer: UIStackView!
    
    @IBOutlet weak var qualityInteractiveView: InteractiveView!
    @IBOutlet weak var qualityLabel: DefaultLabel!
    
    @IBOutlet weak var optimizedInteractiveView: InteractiveView!
    @IBOutlet weak var optimizedLabel: DefaultLabel!
    @IBOutlet weak var optimizedImageView: UIImageView!
    
    @IBOutlet weak var balancedInteractiveView: InteractiveView!
    @IBOutlet weak var balancedLabel: DefaultLabel!
    @IBOutlet weak var balancedImageView: UIImageView!
    
    @IBOutlet weak var bestInteractiveView: InteractiveView!
    @IBOutlet weak var bestLabel: DefaultLabel!
    @IBOutlet weak var bestImageView: UIImageView!
    
    private var isHide = true
    var didFinishAction: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupSettingsSection()
    }
    
    private func setupSettingsSection() {
        
        optimizedImageView.isHidden = true
        balancedImageView.isHidden = true
        bestImageView.isHidden = true
        
        qualityContainer.isHidden = true
        
        qualityInteractiveView.didTouchAction = {
            if self.qualityContainer.isHidden == true {
                self.qualityContainer.isHidden = false
                self.showHideImageView.image = UIImage(named: "hide")
            } else {
                self.qualityContainer.isHidden = true
                self.showHideImageView.image = UIImage(named: "show")
            }
        }
        
        optimizedInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            try? StreamConfiguration.current.realm?.write {
                StreamConfiguration.current.resolutionType = .low
            }
            self.updateUIbasedOnQuality()
        }
        
        balancedInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            SubscriptionSpotsManager.shared.requestSpot(for: DataManager.SubscriptionSpotType.resolution.rawValue) { [weak self] (success) in
                guard let self = self else { return }
                if success {
                    DispatchQueue.main.async {
                        try? StreamConfiguration.current.realm?.write {
                            StreamConfiguration.current.resolutionType = .medium
                        }
                        self.updateUIbasedOnQuality()
                    }
                    
                }
            }
        }
        
        bestInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            SubscriptionSpotsManager.shared.requestSpot(for: DataManager.SubscriptionSpotType.resolution.rawValue) { [weak self] (success) in
                guard let self = self else { return }
                if success {
                    DispatchQueue.main.async {
                        try? StreamConfiguration.current.realm?.write {
                            StreamConfiguration.current.resolutionType = .high
                        }
                        self.updateUIbasedOnQuality()
                    }
                    
                }
            }
        }
        
       
        updateUIbasedOnQuality()
    }
    
    private func updateUIbasedOnQuality(){
        let currentQuality = StreamConfiguration.current.resolutionType
        switch currentQuality {
        case .low:
            qualityLabel.text = NSLocalizedString("Screen.Mirror.Quality.Optimized", comment: "")
            optimizedImageView.isHidden = false
            balancedImageView.isHidden = true
            bestImageView.isHidden = true
        case .medium:
            qualityLabel.text = NSLocalizedString("Screen.Mirror.Quality.Balanced", comment: "")
            balancedImageView.isHidden = false
            optimizedImageView.isHidden = true
            bestImageView.isHidden = true
        case .high:
            qualityLabel.text = NSLocalizedString("Screen.Mirror.Quality.Best", comment: "")
            bestImageView.isHidden = false
            balancedImageView.isHidden = true
            optimizedImageView.isHidden = true
        default:
            optimizedImageView.isHidden = false
            balancedImageView.isHidden = true
            bestImageView.isHidden = true
        }
    }
    
}
