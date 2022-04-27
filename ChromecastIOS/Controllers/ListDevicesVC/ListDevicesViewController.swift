//
//  TutorialListDevicesViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 26.04.2022.
//

import UIKit

class ListDevicesViewController: AFFloatingPanelViewController {
    
    @IBOutlet weak var devicesStackView: UIStackView!
    
    @IBOutlet weak var dotsIndicatorView: DotsActivityIndicator!
    @IBOutlet weak var refereshInteractiveView: InteractiveView!
    @IBOutlet weak var refreshIcon: UIImageView!
    @IBOutlet weak var attentionContainer: UIView!
    
    
    var didFinishAction: (() -> ())?
    private let arrayOfTVs: [String] = ["Samsung", "Sony", "LG"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDotsIndicator()
        
        refereshInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.handleTapOnRefreshButton()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
  
    }
    
    private func populateStackView(tvName: String) {
        let cellView = DeviceCellView()
        cellView.nameLabel.text = tvName
        cellView.containerInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
            
        }
        devicesStackView.addArrangedSubview(cellView)
        devicesStackView.reloadInputViews()
    }
    
    
    private func setupDotsIndicator() {
        dotsIndicatorView.colors = [UIColor(hexString: "#FDAC53"), UIColor(hexString: "#007AFF"), UIColor(hexString: "#A0DAA9")]
        dotsIndicatorView.startAnimating()
    }
    
    private func handleTapOnRefreshButton() {
        //temp as
        attentionContainer.isHidden = true
        
        for i in arrayOfTVs {
            populateStackView(tvName: i)
        }
        
        self.rotate(self.refreshIcon)
        
        self.showAlertLocalNetworkPermissionRequired { [weak self] in
            guard let _ = self else { return }
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            guard UIApplication.shared.canOpenURL(settingsURL) else { return }
            UIApplication.shared.open(settingsURL, completionHandler: nil)
        }
    }
    
    private func rotate(_ targetView: UIView) {
        targetView.layer.removeAllAnimations()
        
        let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Float(Double.pi * 2))
        rotation.duration = 1
        rotation.isCumulative = true
        rotation.repeatCount = 5
        rotation.isRemovedOnCompletion = true
        targetView.layer.add(rotation, forKey: "rotationAnimation")
    }
    
    private func showAlertLocalNetworkPermissionRequired(onComplete: (() -> ())?) {
        
        let alertView = AlertViewController(
            alertTitle: NSLocalizedString("Alert.Permissions.Denied.LocalNetwork.Title", comment: ""),
            alertSubtitle: NSLocalizedString("Alert.Permissions.Denied.LocalNetwork.Subtitle", comment: ""),
            continueAction: NSLocalizedString("Alert.Permissions.Denied.LocalNetwork.Continue", comment: "")
        )
        
        alertView.continueClicked = {
            onComplete?()
            alertView.dismiss()
        }
        
        alertView.present(from: self)
    }
    
}
