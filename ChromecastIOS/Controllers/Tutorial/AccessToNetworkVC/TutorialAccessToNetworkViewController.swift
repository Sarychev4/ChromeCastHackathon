//
//  AccessToNetworkViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 25.04.2022.
//

import UIKit
import GoogleCast
import RealmSwift
import Agregator

class TutorialAccessToNetworkViewController: BaseViewController {
    
    deinit {
        print(">>> deinit TutorialAccessToNetworkViewController")
    }
    
    let kReceiverAppID = "2C5BA44D"// kGCKDefaultMediaReceiverApplicationID //
    let kDebugLoggingEnabled = true
    
    @IBOutlet weak var continueInteractiveView: InteractiveView!
    @IBOutlet weak var continueLabel: DefaultLabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var didFinishAction: (() -> ())?
    var source: String!
    var nameForEvents: String { return "Access to network screen" }
    
    private var isAnimating: Bool = false
    private var allowClicked = false
    private var isAlertShown = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        AgregatorLogger.shared.log(eventName: "Tutorial_shown",
                                   parameters: ["Tutorial Step": nameForEvents, "Source": source])
        
        continueInteractiveView.cornerRadius = 8 * SizeFactor
        continueInteractiveView.didTouchAction = { [weak self] in
            guard let self = self, self.isAnimating == false else { return }
           
            if self.allowClicked {
                LocalNetworkPermissionsManager.shared.checkUserPermissonsLocalNetwork(onComplete: { (success) in
                    if success {
                        
                        ChromeCastService.shared.initialize()
                        
                        self.didFinishAction?()
                        self.didFinishAction = nil
                    } else {
                        self.showAlertLocalNetworkPermissionRequired {
                            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                            
                            if UIApplication.shared.canOpenURL(settingsURL) {
                                UIApplication.shared.open(settingsURL, completionHandler: { (success) in
                                    
                                })
                            }
                        }
                    }
                })
            } else {
                self.isAnimating = true
                self.allowClicked = true
                
                LocalNetworkPermissionsManager.shared.checkUserPermissonsLocalNetwork(onComplete: { (success) in
                    
                })
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    guard let self = self else { return }
                    //Если вдруг системный алерт не показался, то меняем кнопку чтобы можно было пойти дальше
                    if self.isAlertShown == false {
                        self.finishProcessing()
                    }
                }
            }
        }

        /*
         */
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForegroundAction),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willResignActiveNotification),
            name: UIApplication.willResignActiveNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActiveNotification),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
        /*
         */
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func willEnterForegroundAction() {
        AgregatorLogger.shared.log(eventName: "Tutorial_shown",
                                   parameters: ["Tutorial Step": nameForEvents, "Source": "Launch"])
    }
    
    @objc private func willResignActiveNotification() {
        if allowClicked {
            isAlertShown = true
        }
    }
     
    @objc private func didBecomeActiveNotification() {
        if isAlertShown {
            finishProcessing()
        }
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
    
    private func finishProcessing() {
        activityIndicator.startAnimating()
        continueLabel.isHidden = true
        let delay = Double(2)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.isAnimating = false
            self.activityIndicator.stopAnimating()
            self.continueLabel.isHidden = false
            self.continueLabel.text = NSLocalizedString("Common.Continue", comment: "")
            self.continueInteractiveView.bounce(onComplete: nil)
        }
    }
    
}


