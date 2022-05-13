//
//  BrowserViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 20.04.2022.
//

import UIKit
import WebKit

class BrowserViewController: BaseViewController {

    @IBOutlet weak var backInteractiveView: InteractiveView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var webViewContainer: UIView!
    @IBOutlet weak var openWebsitesInteractiveView: InteractiveView! {
        didSet {
            openWebsitesInteractiveView.didTouchAction = {
                self.navigation?.pushViewController(OpenWebsitesViewController(), animated: .left)
            }
        }
    }
    
    private let scriptMessageHandlerName = "test"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupWebView()
        
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.navigation?.popViewController(self, animated: true)
        }
    }
    
    //MARK: - Setup WebView
    private func setupWebView(){
        let webViewConfig = WKWebViewConfiguration()
        webViewConfig.allowsInlineMediaPlayback = true
        webViewConfig.mediaTypesRequiringUserActionForPlayback = .video
        webViewConfig.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        let webView = WKWebView(frame: .zero, configuration: webViewConfig)
        webView.navigationDelegate = self
        
        let indexURL = Bundle.main.url(forResource: "Index", withExtension: "html")
        webView.loadFileURL(indexURL!, allowingReadAccessTo: indexURL!)
//        webView.scrollView.delegate = self
        print(Bundle.main.bundleURL)
        webView.scrollView.backgroundColor = .clear
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.keyboardDismissMode = .onDrag
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        webViewContainer.addSubview(webView)
        webView.leadingAnchor.constraint(equalTo: webViewContainer.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: webViewContainer.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: webViewContainer.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: webViewContainer.bottomAnchor).isActive = true
        
    }


}

//MARK: - Extensions

extension BrowserViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
    }
}
