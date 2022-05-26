//
//  TutorialPreviewImageViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 26.04.2022.
//

import UIKit
import Agregator

class TutorialPreviewImageViewController: BaseViewController {

    deinit {
        print(">>> deinit TutorialPreviewImageViewController")
    }
    
    @IBOutlet weak var continueInteractiveView: InteractiveView!
    @IBOutlet weak var continueLabel: DefaultLabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var dontSeeImageInteractiveLabel: InteractiveLabel!
    
    var didFinishAction: (() -> ())?
    var source: String!
    var nameForEvents: String {
        return "See the image screen"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        AgregatorLogger.shared.log(eventName: "Tutorial_shown",
                                   parameters: ["Tutorial Step": nameForEvents, "Source": source])
        
        continueInteractiveView.cornerRadius = 8 * SizeFactor
        continueInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
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
            self.checkInternetConnection {
                let viewController = SetupChromeCastViewController()
                viewController.modalPresentationStyle = .fullScreen
                viewController.hideInteractiveViewCompletion = {
                    viewController.closeInteractiveView.isHidden = true
                }
                self.navigationController?.pushViewController(viewController, animated: true)
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
