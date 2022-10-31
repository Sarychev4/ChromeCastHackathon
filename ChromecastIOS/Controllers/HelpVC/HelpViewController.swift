//
//  InfoViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 10.05.2022.
//

import UIKit
import WebKit

class HelpViewController: BaseViewController, WKNavigationDelegate {

    /*
     MARK: -
     */
    @IBOutlet weak var backIconImageView: UIImageView!
    
    @IBOutlet var titleLabel: DefaultLabel!
    @IBOutlet var backInteractiveView: InteractiveView!
    @IBOutlet var wkWebView: WKWebView!
    
    /*
     MARK: -
     */
    
    var url: URL?
    var didFinishAction: Closure!
    
    /*
     MARK: -
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        /*
         */
        
        titleLabel.text = title
        
        /*
         */
        
        backInteractiveView.didTouchAction = { [weak self] in
            self?.didFinishAction()
        }
        
        /*
         */
        
        wkWebView.navigationDelegate = self
        wkWebView.scrollView.backgroundColor = UIColor.clear
        
        if let url = url {
            let request = URLRequest(url: url)
            wkWebView.load(request)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    /*
     MARK: - WKNavigationDelegate
     */
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if url.absoluteString == "https://apps.apple.com/app/id1529106085", let appURL = URL(string: "itms-apps://itunes.apple.com/app/id1529106085") {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        } else {
            
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
            decisionHandler(.allow)
        }
    }
}
