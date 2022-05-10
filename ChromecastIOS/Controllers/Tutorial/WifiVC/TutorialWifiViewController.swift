//
//  WifiViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 25.04.2022.
//

import UIKit
import GoogleCast

class TutorialWifiViewController: BaseViewController {
    
    @IBOutlet weak var continueInteractiveView: InteractiveView!
    @IBOutlet weak var continueLabel: DefaultLabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var didFinishAction: (() -> ())?
    
//    let kReceiverAppID = "2C5BA44D" //kGCKDefaultMediaReceiverApplicationID
//    let kDebugLoggingEnabled = true
    override func viewDidLoad() {
        super.viewDidLoad()

        continueInteractiveView.cornerRadius = 8 * SizeFactor
        continueInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.didFinishAction?()
        }
        
//        startDiscoveringDevices()
    }
    
//    private func startDiscoveringDevices() {
//        let criteria = GCKDiscoveryCriteria(applicationID: kReceiverAppID)
//        let options = GCKCastOptions(discoveryCriteria: criteria)
//        GCKCastContext.setSharedInstanceWith(options) //coordinates all of the framework's activities
//        GCKLogger.sharedInstance().delegate = self
//        
//        
//    }

}

extension TutorialWifiViewController: GCKLoggerDelegate {
    
}
