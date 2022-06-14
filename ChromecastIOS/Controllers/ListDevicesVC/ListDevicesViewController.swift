//
//  TutorialListDevicesViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 26.04.2022.
//

import UIKit
import RealmSwift
import CoreMedia

class ListDevicesViewController: AFFloatingPanelViewController {
    
    @IBOutlet weak var devicesStackView: UIStackView!
    
    @IBOutlet weak var dotsIndicatorView: DotsActivityIndicator!
    @IBOutlet weak var refereshInteractiveView: InteractiveView!
    @IBOutlet weak var refreshIcon: UIImageView!
    @IBOutlet weak var attentionContainer: UIView!
    
    private var detectedDevices: Results<DeviceObject>?
    private var devicesNotificationToken: NotificationToken?
    
    var didFinishAction: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDotsIndicator()
        
        refereshInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.handleTapOnRefreshButton()
        }
        
        addDevicesObserver()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let realm = try! Realm()
        detectedDevices = realm.objects(DeviceObject.self)
        if detectedDevices?.isEmpty == true {
            attentionContainer.isHidden = false
        } else {
            attentionContainer.isHidden = true
            guard let detectedDevices = detectedDevices else { return }
            for (index, elem) in detectedDevices.enumerated() {
                self.populateStackView(tvName: elem.friendlyName, index: index)
            }
        }
    }
    
    private func addDevicesObserver() {
        let realm = try! Realm()
        detectedDevices = realm.objects(DeviceObject.self)
        
        devicesNotificationToken = detectedDevices?.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .initial(_):
                break
            case .update(let devices, _, _, _):
                if devices.count == 0 {
                    self.attentionContainer.isHidden = false
                    self.devicesStackView.subviews.forEach { (view) in
                        view.removeFromSuperview()
                    }
                } else {
                    self.attentionContainer.isHidden = true
                    self.devicesStackView.subviews.forEach { (view) in
                        view.removeFromSuperview()
                    }
                    for (index, element) in devices.enumerated() {
                        self.populateStackView(tvName: element.friendlyName, index: index)
                    }
                }
                
                
                break
            case .error(_):
                break
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
  
    }
    
    private func populateStackView(tvName: String, index: Int) {
        let cellView = DeviceCellView()
        cellView.nameLabel.text = tvName
        cellView.containerInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            guard let device = self.detectedDevices?[index] else { return }
            print(">>>is connected \(device.isConnected)")
            if device.isConnected || ChromeCastService.shared.isSessionResumed == true {
                self.didFinishAction?()
                self.dismiss(animated: true, completion: nil)
            } else {
                ChromeCastService.shared.connect(to: device.deviceUniqueID, onComplete: { [weak self] success in
                    guard let self = self else { return }

                    if success {
                        let realm = try! Realm()
                        
                        try! realm.write {
                            device.isConnected = true
                            realm.add(device, update: .all)
                        }
                        self.hidePanel { [weak self] in
                            guard let self = self else { return }
                            self.didFinishAction?()
                        }
                    }
                })
            }
            
        }
        devicesStackView.addArrangedSubview(cellView)
        devicesStackView.reloadInputViews()
    }
    
    
    private func setupDotsIndicator() {
        dotsIndicatorView.colors = [UIColor(hexString: "#FDAC53"), UIColor(hexString: "#007AFF"), UIColor(hexString: "#A0DAA9")]
        dotsIndicatorView.startAnimating()
    }
    
    private func handleTapOnRefreshButton() {
        LocalNetworkPermissionsManager.shared.checkUserPermissonsLocalNetwork(onComplete: { [weak self] (success) in
            guard let self = self else { return }
            if success {
                ChromeCastService.shared.startDiscovery()
                self.rotate(self.refreshIcon)
            } else {
                self.showAlertLocalNetworkPermissionRequired { [weak self] in
                    guard let _ = self else { return }
                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                    guard UIApplication.shared.canOpenURL(settingsURL) else { return }
                    UIApplication.shared.open(settingsURL, completionHandler: nil)
                }
            }
        })
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
            continueAction: NSLocalizedString("Alert.Permissions.Denied.LocalNetwork.Continue", comment: ""),
            leftAction: nil,
            rightAction: nil
        )
        
        alertView.continueClicked = {
            onComplete?()
            alertView.dismiss()
        }
        
        alertView.present(from: self)
    }
    
}



