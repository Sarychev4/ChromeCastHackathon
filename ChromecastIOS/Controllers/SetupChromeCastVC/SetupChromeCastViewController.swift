//
//  SetupChromeCastViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 25.05.2022.
//

import UIKit
import WebKit
import Agregator

class SetupChromeCastViewController: BaseViewController {
    
    @IBOutlet weak var backInteractiveView: InteractiveView!
    @IBOutlet weak var closeInteractiveView: InteractiveView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var playInteractiveView: InteractiveView!
    
    @IBOutlet weak var continueInteractiveView: InteractiveView!
    @IBOutlet weak var tapHereForHelpInteractiveLabel: InteractiveLabel!
    
    var hideInteractiveViewCompletion: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AgregatorLogger.shared.log(eventName: "Setup_chromecast", parameters: nil)
        self.navigationController?.isNavigationBarHidden = true
        
        hideInteractiveViewCompletion?()
        
    
        guard let url = URL(string: "https://www.youtube.com/embed/3553FfDSS7w") else { return }
        let urlRequest = URLRequest(url: url)
        self.webView.load(urlRequest)
        self.webView.layer.opacity = 0
        
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            if let navController = self.navigationController {
                navController.popViewController(animated: true)
            } else {
                self.navigation?.popViewController(self, animated: true)
            }
            
        }
        
        closeInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
        }
        
        
        playInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                self.imageView.layer.opacity = 0
                self.playInteractiveView.layer.opacity = 0
                self.webView.layer.opacity = 1
            } completion: { success in
                
            }
        }
        
        tapHereForHelpInteractiveLabel.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.checkInternetConnection {
                let viewController = HelpViewController()
                viewController.title = NSLocalizedString("MoreFAQ", comment: "")
                viewController.url = ChromeCastFAQURL
                viewController.modalPresentationStyle = .fullScreen
                
                if let navController = self.navigationController {
                    viewController.didFinishAction = { [weak self] in
                        guard let self = self else { return }
                        self.navigationController?.popViewController(animated: true)
                    }
                    navController.pushViewController(viewController, animated: true)
                    
                } else {
                    viewController.didFinishAction = { [weak self] in
                        guard let _ = self else { return }
                        viewController.dismiss(animated: true, completion: nil)
                    }
                    self.present(viewController, animated: true, completion: nil)
                    
                }
                
                
                
            }
        }
        
        continueInteractiveView.didTouchAction = { [weak self] in
            guard let _ = self else { return }
            if let url = URL(string: "itms-apps://apple.com/app/id680819774") {
                UIApplication.shared.open(url)
            }
            
        }
    }
    
}
