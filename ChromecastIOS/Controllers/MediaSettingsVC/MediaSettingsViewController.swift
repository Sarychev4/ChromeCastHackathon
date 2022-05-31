//
//  MirrorSettingsViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 04.05.2022.
//

import UIKit

class MediaSettingsViewController: AFFloatingPanelViewController {

   
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
    var currentResolution: ResolutionType!
    var didFinishAction: ((ResolutionType) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupSettingsSection()
    }
    
    private func setupSettingsSection() {
        
        optimizedInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.hidePanel { [weak self] in
                guard let self = self else { return }
                self.didFinishAction?(.low)
            }
        }
        
        balancedInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.hidePanel { [weak self] in
                guard let self = self else { return }
                self.didFinishAction?(.medium)
            }
              
        }
        
        bestInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.hidePanel { [weak self] in
                guard let self = self else { return }
                self.didFinishAction?(.high)
            }
            
        }
        
        updateUIbasedOnQuality()
    }
    
    private func updateUIbasedOnQuality(){
        let currentQuality = self.currentResolution
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
