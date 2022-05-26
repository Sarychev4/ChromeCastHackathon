//
//  SetupChromeCastViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 25.05.2022.
//

import UIKit
import WebKit

class SetupChromeCastViewController: BaseViewController {
    
    @IBOutlet weak var backInteractiveView: InteractiveView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var playInteractiveView: InteractiveView!
    
    @IBOutlet weak var continueInteractiveView: InteractiveView!
    @IBOutlet weak var tapHereForHelpInteractiveLabel: InteractiveLabel!
    
    var didFinishAction: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        
        let url = URL(string: "https://www.youtube.com/embed/6YmWCbgZuts")!
        let urlRequest = URLRequest(url: url)
        self.webView.load(urlRequest)
        self.webView.layer.opacity = 0
        
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.navigationController.popViewController(self, animated: true)
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
        
        continueInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.didFinishAction?()
        }
        
        tapHereForHelpInteractiveLabel.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.checkInternetConnection {
                let viewController = HelpViewController()
                viewController.title = NSLocalizedString("MoreFAQ", comment: "")
                viewController.url = ChromeCastFAQURL
                viewController.modalPresentationStyle = .fullScreen
                
                if let navController = self.navigationController {
                    navController.pushViewController(viewController, animated: true)
                } else {
                    self.present(viewController, animated: true, completion: nil)
                }
                
                
                viewController.didFinishAction = { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
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
