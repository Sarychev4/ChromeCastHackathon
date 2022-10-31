//
//  PremuimLifeTimeViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 28.04.2022.
//

import UIKit
import MBProgressHUD
import Agregator
import DeviceKit
import ApphudSDK

class PremuimLifeTimeViewController: BaseViewController, SubscriptionController {

    deinit {
        print(">>> deinit PremuimLifeTimeViewController")
        AgregatorStore.shared.removeObserver(self, forKeyPath: #keyPath(AgregatorStore.products))
    }
    
    /*
     MARK: -
     */
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var closeInteractiveView: InteractiveView!
    @IBOutlet weak var generalStackView: UIStackView!
    @IBOutlet weak var topStackView: UIStackView!
    @IBOutlet weak var topSubstackView: UIStackView!
    @IBOutlet weak var bottomStackView: UIStackView!
    @IBOutlet weak var bottomSubstackView: UIStackView!
    @IBOutlet var continueInteractiveView: InteractiveView!
    @IBOutlet var firstProductInteractiveView: InteractiveView!
    @IBOutlet var firstProductAccessoryImageView: RoundedImageView!
    @IBOutlet var firstProductTitleLabel: DefaultLabel!
    @IBOutlet var firstProductSubtitleLabel: DefaultLabel!
    @IBOutlet var secondProductInteractiveView: InteractiveView!
    @IBOutlet var secondProductAccessoryImageView: RoundedImageView!
    @IBOutlet var secondProductTitleLabel: DefaultLabel!
    @IBOutlet var secondProductSubtitleLabel: DefaultLabel!
    @IBOutlet var commentsScrollView: UIScrollView!
    @IBOutlet var termsInteractiveLabel: InteractiveLabel!
    @IBOutlet var policyInteractiveLabel: InteractiveLabel!
    @IBOutlet var restoreInteractiveLabel: InteractiveLabel!
    @IBOutlet weak var topTitleLabel: DefaultLabel!
    
    /*
     MARK: -
     */
    
    var spot: SubscriptionSpot!
    var didFinishAction: ClosureBool!
    
    /*
     MARK: -
     */
    
    private var commentsMap = [
        [
            "Name": NSLocalizedString("SubscriptionCommentName1", comment: ""),
            "Text": NSLocalizedString("SubscriptionComment1", comment: "")
        ]
    ]
    
    private var currentCommentIndex = 0 {
        didSet {
            let commentView = commentsViews[currentCommentIndex]
            let contentOffset = CGPoint(x: commentView.frame.origin.x - commentsScrollView.contentInset.left, y: commentsScrollView.contentOffset.y)
            commentsScrollView.setContentOffset(contentOffset, animated: true)
        }
    }
    private var commentsViews: [CommentView] = []
    private var constrantsToRemove: [NSLayoutConstraint] = []
    
    /*
     */
    
    private var isAnimating: Bool = false
    
    /*
     MARK: -
     */
    
    private var selectedIndex = 0 {
        didSet {
            let checkmarkOn = UIImage(named: "CheckMarkSelect")
            let checkMarkOff = UIImage(named: "CheckMarkDeselect")
            firstProductAccessoryImageView.image = selectedIndex == 0 ? checkmarkOn : checkMarkOff
            secondProductAccessoryImageView.image = selectedIndex == 1 ? checkmarkOn : checkMarkOff
             
            let blueBorder = UIColor(named: "AppleBlue")!
            let grayBorder = UIColor(named: "TrueWhite")!.withAlphaComponent(0.2)
            firstProductInteractiveView.borderColor = selectedIndex == 0 ? blueBorder : grayBorder
            secondProductInteractiveView.borderColor = selectedIndex == 1 ? blueBorder : grayBorder
        }
    }
    
    /*
     MARK: -
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isHidden = true
        /*
         */
        
        if Device.current.isOneOf(Device.allDevicesWithSensorHousing + Device.allSimulatorDevicesWithSensorHousing) {
            topStackView.spacing = 24
            topSubstackView.spacing = 40
            generalStackView.spacing = 40
            bottomSubstackView.spacing = 40
        }
        
        let topPadding = UIApplication.shared.windows.filter { $0.isKeyWindow }.first?.safeAreaInsets.top ?? 0
        scrollView.contentInset.top = topPadding
        
        if Settings.current.hideCloseButtonForAttributedUser, Settings.current.isUserAttributionEnabled {
            closeInteractiveView.isHidden = true
        }
        
        closeInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else {
                return
            }
            
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            
            self.didFinishAction(false)
        }
        
        /*
         */
        
        firstProductInteractiveView.layer.cornerRadius = DefaultCornerRadius
        firstProductInteractiveView.borderWidth = 2
        firstProductInteractiveView.didTouchAction = { [weak self] in
            self?.selectedIndex = 0
        }
        
        secondProductInteractiveView.layer.cornerRadius = DefaultCornerRadius
        secondProductInteractiveView.borderWidth = 2
        secondProductInteractiveView.didTouchAction = { [weak self] in
            self?.selectedIndex = 1
        }
        
        selectedIndex = 0
        
        /*
         */
        
        continueInteractiveView.layer.cornerRadius = 19 * SizeFactor
        continueInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else {
                return
            }
            
            /*
             */
            
            self.checkInternetConnection {
                
                guard let firstButtonConfiguration = self.spot.getValue(for: "first_button") as? [String: AnyHashable], let firstProductID = firstButtonConfiguration["product_id"] as? String, let firstProduct = AgregatorStore.shared.getProduct(with: firstProductID) else {
                    self.showFetchingAlert()
                    return
                }
                
                guard let secondButtonConfiguration = self.spot.getValue(for: "second_button") as? [String: AnyHashable], let secondProductID = secondButtonConfiguration["product_id"] as? String, let secondProduct = AgregatorStore.shared.getProduct(with: secondProductID) else {
                    self.showFetchingAlert()
                    return
                }
                
                /*
                 */
                
                let product = self.selectedIndex == 0 ? firstProduct : secondProduct
                
                /*
                 */
                
                let params = [
                    "Source" : self.spot.title,
                    "Product ID" :  product.productId
                ]
                
            
                AgregatorLogger.shared.log(eventName: "Premium Option Selected", parameters: params)
                
                /*
                 */
                
                AgregatorStore.shared.makePayment(for: product) { [weak self] success in
                    guard let self = self else { return }
                     
                    if success {
                        NSObject.cancelPreviousPerformRequests(withTarget: self)
                        
                        self.didFinishAction(false)
                         
                        let params = [
                            "Source" : self.spot.title,
                            "Product ID" :  product.productId
                        ]
                        
                        AgregatorLogger.shared.log(eventName: "Purchased", parameters: params)
                    }
                }
            }
        }
        
        /*
         */
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForegroundNotification), name: UIApplication.willEnterForegroundNotification, object: nil)
        startBouncing()
        
        /*
         */
        
        commentsScrollView.contentInset = UIEdgeInsets(top: 0, left: 16 * SizeFactor, bottom: 0, right: 16 * SizeFactor)
        
        /*
         */
        
        
        termsInteractiveLabel.sizeToFit()
        termsInteractiveLabel.didTouchAction = { [weak self] in
            self?.checkInternetConnection {
                let viewController = HelpViewController()
                viewController.title = NSLocalizedString("MoreTermOfService", comment: "")
                viewController.url = TermsOfUse
                self?.navigationController?.pushViewController(viewController, animated: true)
                
                viewController.didFinishAction = { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
        policyInteractiveLabel.sizeToFit()
        policyInteractiveLabel.didTouchAction = { [weak self] in
            self?.checkInternetConnection {
                let viewController = HelpViewController()
                viewController.title = NSLocalizedString("MorePrivacyPolicy", comment: "")
                viewController.url = PrivacyPolicy
                self?.navigationController?.pushViewController(viewController, animated: true)
                
                viewController.didFinishAction = { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
        
        /*
         */
        
        restoreInteractiveLabel.didTouchAction = { [weak self] in
            guard let self = self else { return }
            
            self.checkInternetConnection {
                AgregatorStore.shared.restoreProducts { (response) in
                    if response {
                        NSObject.cancelPreviousPerformRequests(withTarget: self)
                        self.didFinishAction(false)
                    }
                }
            }
        }
        
        /*
         */
        
        AgregatorStore.shared.addObserver(self, forKeyPath: #keyPath(AgregatorStore.products), options: [.new], context: nil)
        updateUI()
        
        /*
         */
        
        let params = [
            "Source" : spot.title
        ]
        
        AgregatorLogger.shared.log(eventName: "Subscription screen", parameters: params)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        /*
         */
        
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        /*
         */
        
        commentsViews.forEach { commentView in
            commentView.removeFromSuperview()
        }
        
        commentsViews.removeAll()
        
        /*
         */
        
        var posX: CGFloat = 0
        let width = view.bounds.width - 32 * SizeFactor
        for index in 0..<commentsMap.count {
            let commentData = commentsMap[index]
            
            let commentView = CommentView.fromNib()!
            commentView.translatesAutoresizingMaskIntoConstraints = false
            commentView.name = commentData["Name"]
            commentView.text = commentData["Text"]
            commentView.starsImage = UIImage(named: "FiveStarsHotFix")
            
            commentsScrollView.addSubview(commentView)
            commentsViews.append(commentView)
            
            commentView.widthAnchor.constraint(equalToConstant: width).isActive = true
            commentView.heightAnchor.constraint(equalTo: commentsScrollView.heightAnchor).isActive = true
            
            commentView.topAnchor.constraint(equalTo: commentsScrollView.topAnchor, constant: 0).isActive = true
            commentView.leadingAnchor.constraint(equalTo: commentsScrollView.leadingAnchor, constant: posX).isActive = true
            
            posX += width + 8 * SizeFactor
        }
        
        perform(#selector(scrollToNextComment), with: nil, afterDelay: 3)
    }
    
    /*
     MARK: -
     */
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        updateUI()
    }
    
    /*
     MARK: -
     */
    
    @objc
    private func scrollToNextComment() {
        
        if currentCommentIndex < commentsViews.count - 1 {
            currentCommentIndex += 1
        } else {
            currentCommentIndex = 0
        }
        perform(#selector(scrollToNextComment), with: nil, afterDelay: 3)
    }
    
    private func showFetchingAlert() {
        let alertController = UIAlertController(title: nil, message: "Still fetching products...", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { action in
            
        }
        
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func updateUI() {
        
        /*
         Получаем конфигурации кнопок.
         */
        
        if let captionConfiguration = spot.getValue(for: "caption") as? String {
            topTitleLabel.text = captionConfiguration
        }
        
        guard let firstButtonConfiguration = spot.getValue(for: "first_button") as? [String: AnyHashable], let secondButtonConfiguration = spot.getValue(for: "second_button") as? [String: AnyHashable] else {
            return
        }
        
        /*
         Получаем продукты исходя из конфигурации.
         */
        
        guard let firstProductID = firstButtonConfiguration["product_id"] as? String, let secondProductID = secondButtonConfiguration["product_id"] as? String, let firstProduct = AgregatorStore.shared.getProduct(with: firstProductID), let secondProduct = AgregatorStore.shared.getProduct(with: secondProductID) else {
            return
        }
        
        /*
         Настраиваем UI.
         */
        
        let firstButtonPrice = firstProduct.skProduct?.localizedPrice?.swapPriceAndCurrency ?? ""
        var firstButtonPriceDivided = firstProduct.price
        let secondButtonPrice = secondProduct.skProduct?.localizedPrice?.swapPriceAndCurrency ?? ""
        var secondButtonPriceDivided = secondProduct.price
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.roundingMode = .down
        formatter.maximumFractionDigits = 2
        
        if let product = firstProduct.skProduct, let devider = firstButtonConfiguration["price_divider"] as? NSNumber {
            formatter.locale = product.priceLocale
            
            let number = NSNumber(value: product.price.floatValue / devider.floatValue)
            if let formattedPrice = formatter.string(from: number) {
                firstButtonPriceDivided = formattedPrice.swapPriceAndCurrency
            }
        }
        
        if let product = secondProduct.skProduct, let value = secondButtonConfiguration["price_divider"] as? NSNumber {
            formatter.locale = product.priceLocale
            
            let number = NSNumber(value: product.price.floatValue / value.floatValue)
            if let formattedPrice = formatter.string(from: number) {
                secondButtonPriceDivided = formattedPrice.swapPriceAndCurrency
            }
        }
         
        if Settings.current.isUserAttributionEnabled {
            if let value = firstButtonConfiguration["title_for_ASA"]?.localizedValue as? String {
                firstProductTitleLabel.text = value.replacingOccurrences(of: "[price]", with: firstButtonPrice).replacingOccurrences(of: "[divided_price]", with: firstButtonPriceDivided)
            }
            
            if let value = firstButtonConfiguration["subtitle_for_ASA"]?.localizedValue as? String {
                firstProductSubtitleLabel.text = value.replacingOccurrences(of: "[price]", with: firstButtonPrice).replacingOccurrences(of: "[divided_price]", with: firstButtonPriceDivided)
            }
            
            if let value = secondButtonConfiguration["title_for_ASA"]?.localizedValue as? String {
                secondProductTitleLabel.text = value.replacingOccurrences(of: "[price]", with: secondButtonPrice).replacingOccurrences(of: "[divided_price]", with: secondButtonPriceDivided)
            }
            
            if let value = secondButtonConfiguration["subtitle_for_ASA"]?.localizedValue as? String {
                secondProductSubtitleLabel.text = value.replacingOccurrences(of: "[price]", with: secondButtonPrice).replacingOccurrences(of: "[divided_price]", with: secondButtonPriceDivided)
            }
            
            if let value = secondButtonConfiguration["color_for_ASA"] as? String {
                firstProductSubtitleLabel.textColor = UIColor(hexString: value)
                secondProductSubtitleLabel.textColor = UIColor(hexString: value)
            }
        } else {
            if let value = firstButtonConfiguration["title"]?.localizedValue as? String {
                firstProductTitleLabel.text = value.replacingOccurrences(of: "[price]", with: firstButtonPrice).replacingOccurrences(of: "[divided_price]", with: firstButtonPriceDivided)
            }
            
            if let value = firstButtonConfiguration["subtitle"]?.localizedValue as? String {
                firstProductSubtitleLabel.text = value.replacingOccurrences(of: "[price]", with: firstButtonPrice).replacingOccurrences(of: "[divided_price]", with: firstButtonPriceDivided)
            }
            
            if let value = secondButtonConfiguration["title"]?.localizedValue as? String {
                secondProductTitleLabel.text = value.replacingOccurrences(of: "[price]", with: secondButtonPrice).replacingOccurrences(of: "[divided_price]", with: secondButtonPriceDivided)
            }
            
            if let value = secondButtonConfiguration["subtitle"]?.localizedValue as? String {
                secondProductSubtitleLabel.text = value.replacingOccurrences(of: "[price]", with: secondButtonPrice).replacingOccurrences(of: "[divided_price]", with: secondButtonPriceDivided)
            }
            
            if let value = secondButtonConfiguration["color"] as? String {
                firstProductSubtitleLabel.textColor = UIColor(hexString: value)
                secondProductSubtitleLabel.textColor = UIColor(hexString: value)
            }
        }
         
        
        
    }
    
    private func setupFirstProduct() {
        
    }
    
    private func setupSecondProduct() {
        
    }
    
    @objc
    private func willEnterForegroundNotification() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(startBouncing), object: nil)
        isAnimating = false
        startBouncing()
    }
    
    @objc
    private func startBouncing() {
        
        guard let value = spot?.getValue(for: "is_bouncing_enabled") as? Bool, value == true, isAnimating == false else {
            return
        }
        
        isAnimating = true
        
        UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction], animations: {
            self.continueInteractiveView.transform = CGAffineTransform.identity.scaledBy(x: 1.05, y: 1.05)
        }) { (isFinished) in
            UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction], animations: {
                self.continueInteractiveView.transform = CGAffineTransform.identity
            }) { (isFinished) in
                UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction], animations: {
                    self.continueInteractiveView.transform = CGAffineTransform.identity.scaledBy(x: 1.05, y: 1.05)
                }) { (isFinished) in
                    UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction], animations: {
                        self.continueInteractiveView.transform = CGAffineTransform.identity
                    }) { (isFinished) in
                        self.continueInteractiveView.transform = CGAffineTransform.identity
                        self.isAnimating = false
                        self.perform(#selector(self.startBouncing), with: nil, afterDelay: 1)
                    }
                }
            }
        }
    }

}
