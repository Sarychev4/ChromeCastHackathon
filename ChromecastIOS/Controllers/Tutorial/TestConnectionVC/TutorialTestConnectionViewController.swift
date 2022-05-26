//
//  TestConnectionViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 26.04.2022.
//

import UIKit
import Agregator

class TutorialTestConnectionViewController: BaseViewController {

    deinit {
        print(">>> deinit TutorialTestConnectionViewController")
    }
    
    @IBOutlet weak var continueInteractiveView: InteractiveView!
    @IBOutlet weak var continueLabel: DefaultLabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var dontSeeImageInteractiveLabel: InteractiveLabel!
    
    var didFinishAction: (() -> ())?
    var source: String!
    var nameForEvents: String {
        return "Test connection screen"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AgregatorLogger.shared.log(eventName: "Tutorial_shown",
                                   parameters: ["Tutorial Step": nameForEvents, "Source": source])
        
        continueInteractiveView.cornerRadius = 8 * SizeFactor
        continueInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            let ipAddress = ServerConfiguration.shared.deviceIPAddress()
            guard let url = URL(string: "http://\(ipAddress):\(Port.app.rawValue)/image/\(UUID().uuidString)") else { return }
            ChromeCastService.shared.displayImage(with: url)
            self.didFinishAction?()
        }
        
        /*
         */
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForegroundAction),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
        
        /*
         */
        
        dontSeeImageInteractiveLabel.didTouchAction = { [weak self] in
            guard let self = self else { return }
            let viewController = SetupChromeCastViewController()
            viewController.modalPresentationStyle = .fullScreen
            
            if let navController = self.navigationController {
                navController.pushViewController(viewController, animated: true)
            } else {
                self.present(viewController, animated: true, completion: nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func willEnterForegroundAction() {
        AgregatorLogger.shared.log(eventName: "Tutorial_shown",
                                   parameters: ["Tutorial Step": nameForEvents, "Source": "Launch"])
    }

}
