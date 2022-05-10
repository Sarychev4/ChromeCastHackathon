//
//  AccessToNetworkViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 25.04.2022.
//

import UIKit
import GoogleCast
import RealmSwift

class TutorialAccessToNetworkViewController: BaseViewController {
    
    let kReceiverAppID = "2C5BA44D"// kGCKDefaultMediaReceiverApplicationID //
    let kDebugLoggingEnabled = true
    
    @IBOutlet weak var continueInteractiveView: InteractiveView!
    @IBOutlet weak var continueLabel: DefaultLabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var didFinishAction: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        continueInteractiveView.cornerRadius = 8 * SizeFactor
        continueInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.didFinishAction?()
        }

        ChromeCastService.shared.initialize()
    }
}


