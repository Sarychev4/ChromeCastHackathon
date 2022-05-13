//
//  PremiumDiscountViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 28.04.2022.
//

import UIKit
import MBProgressHUD
import RealmSwift
import Agregator
import DeviceKit
import ApphudSDK

class PremiumDiscountViewController: BaseViewController {

    deinit {
        print(">>> deinit PremiumDiscountViewController")
        AgregatorStore.shared.removeObserver(self, forKeyPath: #keyPath(AgregatorStore.products))
    }
    
    /*
     MARK: -
     */
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet var closeInteractiveView: InteractiveView!
    @IBOutlet var continueInteractiveView: InteractiveView!
    
    @IBOutlet var percentsLabel: DefaultLabel!
    @IBOutlet var priceLabel: DefaultLabel!
    
    @IBOutlet var timerView: UIView!
    @IBOutlet var timerLabel: DefaultLabel!
    
    @IBOutlet var termsInteractiveLabel: InteractiveLabel!
    @IBOutlet var policyInteractiveLabel: InteractiveLabel!
    @IBOutlet var subscriptionTermsInteractiveLabel: InteractiveLabel!
    
    @IBOutlet var restoreInteractiveLabel: InteractiveLabel!
    
    @IBOutlet weak var topStackView: UIStackView!
    @IBOutlet weak var topSubstackView: UIStackView!
    @IBOutlet weak var mainStackView: UIStackView!
    
    /*
     MARK: -
     */
    
    var didFinishAction: ClosureBool!
    
    /*
     Спот, вместо которого был отображён экран Special Offer.
     */
    
    var spot: SubscriptionSpot!
    var source: String!
    
    /*
     MARK: -
     */
    
    private var isAnimating: Bool = false
    private var notificationToken: NotificationToken!
    
    /*
     MARK: -
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isHidden = true
        
        /*
         .iPhoneX, .iPhoneXS, .iPhoneXSMax, .iPhoneXR, .iPhone11, .iPhone11Pro, .iPhone11ProMax, .iPhone12, .iPhone12Mini, .iPhone12Pro, .iPhone12ProMax, .iPhone13, .iPhone13Mini, .iPhone13Pro, .iPhone13ProMax
         */
        
        if Device.current.isOneOf(Device.allDevicesWithSensorHousing + Device.allSimulatorDevicesWithSensorHousing) {
            topStackView.spacing = 40
           // topSubstackView.spacing = 32
            mainStackView.spacing = 100 * SizeFactor
        }
        
        /*
         */
        
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
        
        if let value = spot?.getSpecialOfferValue(for: "discount_value") as? NSNumber {
            let intValue = Int(value.floatValue * 100)
            
            let string = "-\(intValue)%"
           // percentsLabel.text = string
        }
        
        /*
         */
        
        timerView.layer.cornerRadius = 8 * SizeFactor
        
        /*
         */
        
        continueInteractiveView.layer.cornerRadius = 8 * SizeFactor
        continueInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else {
                return
            }
            
            /*
             Останавливаем обзёрвер таймера, что бы экран не закрылся во время покупки.
             */
            
            self.notificationToken.invalidate()
            
            /*
             */
            
            self.checkInternetConnection {
                
                /*
                 */
                
                guard let productID = self.spot?.getSpecialOfferValue(for: "product_id") as? String, let product = AgregatorStore.shared.getProduct(with: productID)
                else {
                    self.updateObserver()
                    self.showFetchingAlert()
                    return
                }
                
                /*
                 */
                
                var params = [
                    "Source" : self.source,
                    "Product ID" : productID
                ]
            
                AgregatorLogger.shared.log(eventName: "Purchase tap", parameters: params)
                
                /*
                 */
                
                AgregatorStore.shared.makePayment(for: product) { paymentSuccess in
                    
                    if paymentSuccess {
                        NSObject.cancelPreviousPerformRequests(withTarget: self)
                        self.didFinishAction(true)
                        
                        /*
                         */
                        
                        let params = [
                            "Source" : self.source,
                            "Product ID" : productID
                        ]

                        AgregatorLogger.shared.log(eventName: "Purchased", parameters: params)
                        
                    } else {
                        self.updateObserver()
                    }
                }
            }
        }
        
        /*
         */
        
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
        
        subscriptionTermsInteractiveLabel.didTouchAction = { [weak self] in
            self?.checkInternetConnection {
                let viewController = HelpViewController()
                viewController.title = NSLocalizedString("Subscription.Default.Policy.SubscriptionTerms", comment: "")
                viewController.url = SubscriptionTerms
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForegroundNotification), name: UIApplication.willEnterForegroundNotification, object: nil)
        startBouncing()
        
        /*
         */
        
        AgregatorStore.shared.addObserver(self, forKeyPath:  #keyPath(AgregatorStore.products), options: [.new], context: nil)
        updateObserver()
        
        /*
         */
        
        var params = [
            "Source" : source
        ]
        
        AgregatorLogger.shared.log(eventName: "Special offer", parameters: nil)
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
    
    private func updateObserver() {
        if Settings.current.specialOfferState == .completed {
            didFinishAction(false)
        } else {
            notificationToken = Settings.current.observe({ [weak self] (change) in
                switch change {
                case .change(_, let properties):
                    for property in properties {
                        if property.name == #keyPath(Settings.specialOfferTimeLeft), let value = property.newValue as? NSNumber {
                            
                            /*
                             Обновляем UI.
                             */
                            
                            self?.updateUI()
                            
                            /*
                             Если таймер вышел - прячем экран.
                             */
                            
                            if value == 0 {
                                self?.didFinishAction(false)
                            }
                        }
                    }
                case .deleted, .error(_):
                    self?.notificationToken.invalidate()
                }
            })
            
            /*
             */
            
            updateUI()
        }
    }
    
    private func updateUI() {
 
        let date = Date(timeIntervalSince1970: Settings.current.specialOfferTimeLeft)
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "HH : mm : ss"
        
        let sentence = dateFormatter.string(from: date) //HH:mm:ss
        let opacityAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .heavy),
            .foregroundColor: UIColor.white.withAlphaComponent(0.5),
        ]
        let regularAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 32, weight: .heavy)]
        let attributedSentence = NSMutableAttributedString(string: sentence, attributes: regularAttributes)

        attributedSentence.setAttributes(opacityAttributes, range: NSRange(location: 3, length: 1))
        attributedSentence.setAttributes(opacityAttributes, range: NSRange(location: 8, length: 1))
       
        
        timerLabel.attributedText = attributedSentence//dateFormatter.string(from: date)
        
        /*
         Получаем продукты исходя из конфигурации.
         */
        
        guard let productID = spot?.getSpecialOfferValue(for: "product_id") as? String, let product = AgregatorStore.shared.getProduct(with: productID) else {
            return
        }
        
        /*
         Настраиваем UI.
         */
        
        
        if let product = product.skProduct {
            var priceDivided = ""
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = 2
            formatter.roundingMode = .down
            formatter.locale = product.priceLocale
             
            if let divider = spot?.getSpecialOfferValue(for: "price_divider") as? NSNumber,
               let value = formatter.string(from: NSNumber(value: product.price.floatValue / divider.floatValue)) {
                priceDivided = value.swapPriceAndCurrency
            }
            
            guard let regex = spot?.getSpecialOfferValue(for: "price_text") as? String,
                  let priceFull = product.localizedPrice?.swapPriceAndCurrency
            else { return }
            
            let string = regex.replacingOccurrences(of: "[price]", with: priceFull).replacingOccurrences(of: "[divided_price]", with: priceDivided)
            let attributedString = NSMutableAttributedString(
                string: string,
                attributes: [.foregroundColor: UIColor.white,
                             .font: UIFont.customFont(weight: .thin, size: 18.0)]
            )
             
            
            let isBold = spot?.getValue(for: "is_bold") as? Bool ?? true
            let priceFontSize = spot?.getValue(for: "font_size") as? CGFloat ?? 18
            let fullPriceRange = (string as NSString).range(of: priceFull)
            attributedString.addAttributes(
                [.font: UIFont.customFont(weight: isBold ? .bold : .thin, size: priceFontSize),
                 .foregroundColor: UIColor.white],
                range: fullPriceRange
            )
            
            let devidedPriceRange = (string as NSString).range(of: priceDivided)
            attributedString.addAttributes(
                [.font: UIFont.customFont(weight: isBold ? .bold : .thin, size: priceFontSize),
                 .foregroundColor: UIColor.white],
                range: devidedPriceRange
            )
            
            priceLabel.attributedText = attributedString
            
        }
    }
    
    private func showFetchingAlert() {
        let alertController = UIAlertController(title: nil, message: "Still fetching products...", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { action in
            
        }
        
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @objc
    private func willEnterForegroundNotification() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(startBouncing), object: nil)
        isAnimating = false
        startBouncing()
    }
    
    @objc
    private func startBouncing() {
        
        guard let value = spot?.getSpecialOfferValue(for: "is_bouncing_enabled") as? Bool,
              value == true,
              isAnimating == false
        else { return }
        
        isAnimating = true
        continueInteractiveView.bounce { [weak self] in
            guard let self = self else { return }
            self.isAnimating = false
            self.perform(#selector(self.startBouncing), with: nil, afterDelay: 3)
        }
    }
}

extension ApphudProduct {
    var price: String {
        guard let price = skProduct?.price.doubleValue else { return "" }
        return String(price)
    }
}

extension AgregatorStore {
    func getProduct(with id: String) -> ApphudProduct? {
        return products?.first(where: { $0.productId == id || $0.name == id})
    }
}


