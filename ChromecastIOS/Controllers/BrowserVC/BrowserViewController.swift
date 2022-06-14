//
//  BrowserViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 20.04.2022.
//

import UIKit
import WebKit
import MBProgressHUD
import Agregator
import DeviceKit
import Realm
import RealmSwift
import Alamofire
import GoogleCast
import ZMJTipView

class BrowserViewController: BaseViewController {

    @IBOutlet weak var navigationBarShadowView: DropShadowView!
    @IBOutlet weak var backInteractiveView: InteractiveView!
    
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var webViewContainer: UIView!
    
    @IBOutlet weak var webBackInteractveView: InteractiveView!
    @IBOutlet weak var webForwardInteractiveView: InteractiveView!
    @IBOutlet weak var openWebsitesInteractiveView: InteractiveView!
    @IBOutlet weak var detectedUrlsInteractiveView: InteractiveView!
    @IBOutlet weak var detectedUrlsLabel: DefaultLabel!
    
    @IBOutlet weak var playDetectevUrlsImageView: UIView!
    
    private var tabsNotificationToken: NotificationToken?
    private var detectedUrlsNotificationToken: NotificationToken?
    private var webView: WKWebView!
    private var browserTabs: Results<BrowserTab>!
    private var detectedUrls: Results<DetectedUrl>?
    private var navigationBarAnimator: UIViewPropertyAnimator!
    private let scriptMessageHandlerName = "test"
    private var scrollViewAnimator: ScrollViewAnimator?
    private var extractor = MediaInfoExtractor()
    
    private var isTipWasShown = false
    private var tipView: ZMJTipView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBrowserTabsObserver()
        setupDetectedUrlsObserver()
        
        setupNavigationSection()
        setupSearchBar()
        setupWebView()
        setupWebSection()
        loadCurrentTab()
        
        setupNavigationAnimations()

    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        guard parent == nil else { return }
        finishAnimation()
        webView.stopLoading()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: scriptMessageHandlerName)
    }
    
    private func setupNavigationSection() {
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.tipView?.isHidden = true
            self.navigation?.popViewController(self, animated: true)
        }
        
        connectInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.presentDevices(postAction: nil)
        }
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.searchTextField.textColor = UIColor.black.withAlphaComponent(0.8)
    }
    
    //MARK: - Setup WebView
    private func setupWebView(){
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .video
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        let userContentController = WKUserContentController()
        userContentController.add(self, name: scriptMessageHandlerName)
        // config.userContentController = userContentController
         
        let scriptSource = webURLSearch
        let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(userScript)
         
        config.userContentController = userContentController
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        webView.scrollView.backgroundColor = .clear
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.keyboardDismissMode = .onDrag
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        webViewContainer.addSubview(self.webView)
        webView.leadingAnchor.constraint(equalTo: webViewContainer.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: webViewContainer.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: webViewContainer.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: webViewContainer.bottomAnchor).isActive = true
        
    }
    
    private func setupWebSection() {
        webBackInteractveView.didTouchAction = {  [weak self] in
            guard let self = self else { return }
            if self.webView.goBack() == nil {
                self.returnToStartPage()
            }
        }
        
        webForwardInteractiveView.didTouchAction = { [weak self] in
            self?.webView.goForward()
        }

        openWebsitesInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            if BrowserTab.current.link.hasPrefix("file:") == false {
                self.createSnapshotOfCurrentPage()
            }
            self.tipView?.isHidden = true
            let viewController = OpenWebsitesViewController()
            self.navigation?.pushViewController(viewController, animated: .left)
        }
        
        detectedUrlsInteractiveView.didTouchAction = { [weak self] in
            guard let self = self, let detectedUrls = self.detectedUrls, detectedUrls.count > 0 else { return }
            self.connectIfNeeded { [weak self] in
                guard let self = self else { return }
                self.tipView?.isHidden = true
                self.presentDetectedUrlsScreen(postAction: nil)
                
            }
        }
    }
    
    private func loadCurrentTab() {
        if browserTabs.count == 0 {
            if let indexURL = Bundle.main.url(forResource: "Index", withExtension:"html") {
                webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL)
            } else {
                guard let googleUrl = URL(string: "https://www.google.com") else { return }
                webView.load(URLRequest(url: googleUrl))
            }
        } else {
            let currentTab = BrowserTab.current
            if currentTab.link.hasPrefix("file"){
                if let indexURL = Bundle.main.url(forResource: "Index", withExtension:"html") {
                    webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL)
                }
            } else {
                guard let currentTabUrl = URL(string: currentTab.link) else { return }
                webView.load(URLRequest(url: currentTabUrl))
            }
        }
    }
    
    private func setupBrowserTabsObserver() {
        let realm = try! Realm()
        browserTabs = realm.objects(BrowserTab.self)
        if browserTabs.isEmpty {
            addDefaultTab()
        }
        tabsNotificationToken = browserTabs.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .initial(_):
                break
            case .update(_, _, _, _):
                self.updateWebViewAddress()
            case .error(_):
                break
            }
        }
    }
    
    @objc func addDefaultTab() {
        let id = UUID().uuidString
        let tab = BrowserTab()
        tab.id = id
        tab.isCurrentTab = true
        
        let realm = try! Realm()
        try! realm.write {
            realm.add([tab])
        }
        print(">>> New Tab was added to the REALM from First Screen")
    }
    
    private func setupDetectedUrlsObserver() {
        let realm = try! Realm()
        detectedUrls = realm.objects(DetectedUrl.self)
        detectedUrlsNotificationToken = detectedUrls?.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .initial(let collection):
                self.setDetectedVideosCount(collection.count)
                break
            case .update(let collection, _, _, _):
                self.setDetectedVideosCount(collection.count)
            case .error(_):
                break
            }
        }
    }
    
    private func setDetectedVideosCount(_ count: Int) {
        let s = count == 1 ? "" : "s"
        if count == 0 {
            self.playDetectevUrlsImageView.isHidden = true
        } else {
            self.playDetectevUrlsImageView.isHidden = false
        }
        self.detectedUrlsLabel.text = "\(count) Video\(s) Detected"
    }
    
    private func updateWebViewAddress() {
        let currentTab = BrowserTab.current
        if currentTab.link.hasPrefix("file") {
            guard let indexURL = Bundle.main.url(forResource: "Index", withExtension:"html") else { return }
            webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL)
        } else {
            guard let currentTabUrl = URL(string: currentTab.link) else { return }
            webView.load(URLRequest(url: currentTabUrl))
        }
    }
    
    private func presentDevices(postAction: (() -> ())?) {
        let controller = ListDevicesViewController()
        controller.canDismissOnPan = true
        controller.isInteractiveBackground = false
        controller.grabberState = .inside
        controller.grabberColor = UIColor.black.withAlphaComponent(0.8)
        controller.modalPresentationStyle = .overCurrentContext
        controller.didFinishAction = {  [weak self] in
            guard let _ = self else { return }
            postAction?()
        }
        present(controller, animated: false, completion: nil)
    }
    
    private func finishAnimation() {
        func finish(_ animator: UIViewPropertyAnimator) {
            animator.stopAnimation(true)
            if animator.state != .inactive {
                animator.finishAnimation(at: .current)
            }
        }
        finish(navigationBarAnimator)
    }
    
    private func returnToStartPage() {
        let currentTab = BrowserTab.current
         
        try! currentTab.realm?.write(withoutNotifying: [tabsNotificationToken!]) {
            currentTab.link = DefaultLocalPage
        }
        updateWebViewAddress()
    }
    
    private func createSnapshotOfCurrentPage() {
        let config = WKSnapshotConfiguration()
        let size = self.webView.scrollView.visibleSize
        config.rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        webView.takeSnapshot(with: nil) { (image, error) in
            guard let image = image,
                  let screenshotData = image.jpegData(compressionQuality: 0.95)
            else { return }
             
            try! BrowserTab.current.realm?.write {
                BrowserTab.current.image = screenshotData
            }
        }
    }
    
    private func presentDetectedUrlsScreen(postAction: Closure?) {
        let controller = DetectedUrlsViewController()
        controller.modalPresentationStyle = .overCurrentContext
        controller.grabberState = .inside
        controller.grabberColor = UIColor.black.withAlphaComponent(0.8)
        controller.didFinishAction = {
            controller.dismiss(animated: false, completion: nil)
            postAction?()
        }
        controller.castToTVClosure = { [weak self, weak controller] value in
            guard let self = self, let controller = controller else { return }
            controller.dismiss(animated: false) {
                self.castToTV(value)
            }
        }
        present(controller, animated: false, completion: nil)
    }
    
    //temp as
    private func castToTV(_ url: String?) {
        
        SubscriptionSpotsManager.shared.requestSpot(for: DataManager.SubscriptionSpotType.browser.rawValue, with: { [weak self] success in
            guard let self = self, success == true else { return }
            self.connectIfNeeded { [weak self] in
                guard let self = self else { return }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                guard let urlString = url, let url = URL(string: urlString) else { return }
                let scriptSource = webVideoStop
                self.webView.evaluateJavaScript(scriptSource) { (object, error) in }
                ChromeCastService.shared.displayVideo(with: url)
                ChromeCastService.shared.showDefaultMediaVC()
            }
        })
    }
    
    private func connectIfNeeded(onComplete: Closure?) {
        guard GCKCastContext.sharedInstance().sessionManager.connectionState.rawValue != 2 else {
            onComplete?()
            return
        }
        presentDevices {
            onComplete?()
        }
    }
    
    private func showTipView() {
        let preferences = ZMJPreferences()
        preferences.drawing.font = UIFont.systemFont(ofSize: 14)
        preferences.drawing.textAlignment = .center
        preferences.drawing.backgroundColor = UIColor(hexString: "FBBB05")
        preferences.positioning.maxWidth = 130
//        preferences.positioning.bubbleVInset = 34
        preferences.drawing.arrowPosition = .bottom
        
        preferences.animating.dismissTransform = CGAffineTransform(translationX: 100, y: 0);
        preferences.animating.showInitialTransform = CGAffineTransform(translationX: 100, y: 0);
        preferences.animating.showInitialAlpha = 0;
        preferences.animating.showDuration = 1;
        preferences.animating.dismissDuration = 1;
        
        let title = NSLocalizedString("Screen.Browser.Tip", comment: "")
        guard let tipView2 = ZMJTipView(text: title, preferences: preferences, delegate: nil) else { return }
        self.tipView = tipView2
        self.tipView?.show(animated: true, for: self.detectedUrlsInteractiveView, withinSuperview: nil)

    }


}

//MARK: - Extensions

extension BrowserViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard let url = webView.url else { return }
        if url.absoluteString.hasPrefix("file:///") {
            searchBar.text = ""
        } else {
            searchBar.text = webView.url?.absoluteString
        }
        
        let currentTab = BrowserTab.current
        
        let realm = try! Realm()
        let allDetectedUrls = realm.objects(DetectedUrl.self)
        
        try! realm.write(withoutNotifying: [tabsNotificationToken!]) {
            currentTab.link = webView.url!.absoluteString
            realm.delete(allDetectedUrls)
        }
    }
}

extension BrowserViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, text.isEmpty == false else { return }

        func searchTextOnGoogle(text: String) {
            let textComponent = text.components(separatedBy: " ")
            let searchString = textComponent.joined(separator: "+")
            guard let googleSearchUrlComponents = URLComponents(string: "https://www.google.com/search") else { return }
            var urlComps = googleSearchUrlComponents
            urlComps.queryItems = [URLQueryItem(name: "q", value: searchString)]
            let url = urlComps.url!
            let urlRequest = URLRequest(url: url)
            webView.load(urlRequest)
        }

        if text.starts(with: "http://") || text.starts(with: "https://"), let url = URL(string: text) {
            let request = URLRequest(url: url)
            webView.load(request)
            print(">>> Text Field was edited HTTP")
        } else if text.contains("www"), let url = URL(string: "http://\(text)") {
            let request = URLRequest(url: url)
            webView.load(request)
            print(">>> Text Field was edited WWW")
        } else {
            searchTextOnGoogle(text: text)
            print(">>> Text Field was edited GOOGLE")
        }
        self.searchBar.endEditing(true)
    }
}

extension BrowserViewController: UIWebViewDelegate, UIScrollViewDelegate {
    private func setupNavigationAnimations() {
        navigationBarShadowView.alpha = 0
        navigationBarAnimator = UIViewPropertyAnimator(duration: 1.0, curve: .easeOut, animations: { [weak self] in
            guard let self = self else { return }
            self.navigationBarShadowView.alpha = 1
        })
        scrollViewAnimator = ScrollViewAnimator(minAnchor: 0, maxAnchor: 100, animator: navigationBarAnimator!)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPosition = scrollView.contentOffset.y + scrollView.contentInset.top
        scrollViewAnimator?.handleAnimation(with: currentPosition)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated && ((navigationAction.request.url?.host?.hasSuffix("youtube.com")) != nil) {
            decisionHandler(.cancel)
                DispatchQueue.main.async {
                webView.load(navigationAction.request)
            }
        } else {
            decisionHandler(.allow)
        }
    }
}

extension BrowserViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageBody = message.body as? [String: String], let url = messageBody["url"] else { return }
        
        let format = url.components(separatedBy: ".").last ?? ""
        
        let detectedUrl = DetectedUrl()
        detectedUrl.url = url
        detectedUrl.format = format.count < 5 ? format : ""
        
        let realm = try! Realm()
        try! realm.write {
            realm.add(detectedUrl, update: .all)
        }
        
        if isTipWasShown == false {
            self.showTipView()
            isTipWasShown = true
        }
        
        detectedUrlsInteractiveView.bounce { }
        
        extractor.getVideoInfoAndCachePreviewImage(from: url) { [weak self] result in
            guard let _ = self else { return }
            
            switch result {
            case .success(let mediaInfo):
                let realm = try! Realm()
                try! realm.write {
                    detectedUrl.size = "\(Int(mediaInfo.size.width))x\(Int(mediaInfo.size.height))"
                    detectedUrl.format = mediaInfo.format
                }
                
            case .failure(_):
                break
            }
            
        }
    }
}

extension BrowserViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        searchBar.selectAll(self)
    }
}
