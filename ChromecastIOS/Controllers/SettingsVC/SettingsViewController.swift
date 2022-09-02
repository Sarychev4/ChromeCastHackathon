//
//  SettingsViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 21.04.2022.
//

import UIKit
import MBProgressHUD
import Agregator
import MessageUI
import SystemConfiguration.CaptiveNetwork
import NetworkExtension
import DeviceKit
import StoreKit
import RealmSwift

class SettingsViewController: BaseViewController {
    deinit {
        print(">>> deinit SettingsViewController")
    }
    
//    @IBOutlet weak var closeCrossInteractiveView: InteractiveView!
    @IBOutlet weak var contentScrollView: UIScrollView!
    @IBOutlet weak var containerStackView: UIStackView!
    @IBOutlet weak var specialOfferContainerView: UIView!
    @IBOutlet weak var specialOfferInteractiveView: InteractiveView!
    @IBOutlet weak var premiumLabel: DefaultLabel!
    
    @IBOutlet weak var faqInteractiveView: InteractiveView!
    @IBOutlet weak var restorePurchasesInteractiveView: InteractiveView!
    @IBOutlet weak var privacyPolicyInteractiveView: InteractiveView!
    @IBOutlet weak var termsOfUseInteractiveView: InteractiveView!
    @IBOutlet weak var sendUsANoteInteractiveView: InteractiveView!
    @IBOutlet weak var needHelpInteractiveLabel: InteractiveLabel!
    
    private var applicationNotificationToken: NotificationToken!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        specialOfferContainerView.isHidden = AgregatorApplication.current.subscriptionState == .active
      
        setupHelpSection()
//        setupNavigationSection()
        observeSubscriptionState()
        
        let sentence = NSString(string: NSLocalizedString("Screen.Settings.Banner.Title", comment: ""))
        let range = (sentence).range(of: "Premium")
        let attribute = NSMutableAttributedString.init(string: sentence as String)
        attribute.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 24, weight: .black), range: range)
        attribute.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(hexString: "FBBB05"), range: range)
        premiumLabel.attributedText = attribute
        
        specialOfferInteractiveView.didTouchAction = { [weak self] in
            AgregatorLogger.shared.log(eventName: "Banner tap", parameters: ["Source": "Settings"])
            SubscriptionSpotsManager.shared.requestSpot(for: DataManager.SubscriptionSpotType.settings.rawValue, with: { [weak self] success in
                self?.containerStackView.reloadInputViews()
            })
            
        }
        /*
         */
        
        
        privacyPolicyInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.checkInternetConnection { [weak self] in
                guard let self = self else { return }
                let viewController = HelpViewController()
                viewController.title = NSLocalizedString("MorePrivacyPolicy", comment: "")
                viewController.url = PrivacyPolicy
                viewController.hidesBottomBarWhenPushed = true
                self.navigation?.pushViewController(viewController, animated: .left)
                
                viewController.didFinishAction = { [weak self] in
                    guard let self = self else { return }
                    self.navigation?.popViewController(viewController, animated: true)
                }
            }
        }
        
        /*
         */
        
        faqInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.checkInternetConnection {
                let viewController = SetupChromeCastViewController()
                viewController.modalPresentationStyle = .fullScreen
                viewController.hidesBottomBarWhenPushed = true
                viewController.hideInteractiveViewCompletion = {
                    viewController.closeInteractiveView.isHidden = true
                }
                self.navigation?.pushViewController(viewController, animated: .left)
            }
        }
        
        
        /*
         */
        
        termsOfUseInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.checkInternetConnection { [weak self] in
                guard let self = self else { return }
                let viewController = HelpViewController()
                viewController.title = NSLocalizedString("MoreTermOfService", comment: "")
                viewController.url = TermsOfUse
                viewController.hidesBottomBarWhenPushed = true
                self.navigation?.pushViewController(viewController, animated: .left)
                
                viewController.didFinishAction = { [weak self] in
                    guard let self = self else { return }
                    self.navigation?.popViewController(viewController, animated: true)
                }
            }
        }
        
        /*
         */
        
        sendUsANoteInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.checkInternetConnection { [weak self] in
                guard let self = self else { return }
                let systemVersion = UIDevice.current.systemVersion
                let bundleVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
                var storeCountry = AgregatorStore.shared.products?.first?.skProduct?.priceLocale.regionCode ?? Locale.current.regionCode
                storeCountry = SKPaymentQueue.default().storefront?.countryCode ?? ""
                let toRecipient = Settings.current.supportEmail
                let subject = "[Screen Mirroring] User Feedback"
                let body = """
                {Please describe your problem below}\n
                
                
                
                
                {Your device information is included to help the developer track your feedback}
                
                Phone: \(Device.current.description)
                TV: \("-")
                App Version: \(bundleVersion)
                OS: \(systemVersion)
                Country: \(storeCountry ?? "")
                Device ID: \(UIDevice.current.identifierForVendor?.uuidString ?? "-")
                """
                
                if MFMailComposeViewController.canSendMail() {
                    let viewController = MFMailComposeViewController()
                    viewController.mailComposeDelegate = self
                    viewController.setToRecipients([toRecipient])
                    viewController.setSubject(subject)
                    viewController.setMessageBody(body, isHTML: false)
                    self.present(viewController, animated: true)
                } else if let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let url = URL(string: "mailto:\(toRecipient)?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
        
        /*
         */
        
        restorePurchasesInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            
            self.checkInternetConnection {
                AgregatorStore.shared.restoreProducts { (response) in
                    if response {
                        NSObject.cancelPreviousPerformRequests(withTarget: self)
                    }
                }
            }
        }
        
        /*
         */
    }
    
    /*
     MARK: -
     */
    
    private func setupHelpSection() {
        needHelpInteractiveLabel.attributedText = NSAttributedString(string: NSLocalizedString("Screen.Settings.Help.Title", comment: ""), attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        
        needHelpInteractiveLabel.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.checkInternetConnection {
                let viewController = SetupChromeCastViewController()
//                viewController.modalPresentationStyle = .fullScreen
                viewController.hidesBottomBarWhenPushed = true
                viewController.hideInteractiveViewCompletion = {
                    viewController.closeInteractiveView.isHidden = true
                }
                self.navigation?.pushViewController(viewController, animated: .left)
            }
        }
    }
    
//    private func setupNavigationSection() {
//        closeCrossInteractiveView.didTouchAction = { [weak self] in
//            guard let self = self else { return }
//            self.dismiss(animated: true)
//           // self.navigation?.popViewController(self, animated: true)
//        }
//    }
    
    private func observeSubscriptionState() {
        applicationNotificationToken = AgregatorApplication.current.observe({ [weak self] (change) in
            switch change {
            case .change(_, let properties):
                for property in properties {
                    if property.name == #keyPath(AgregatorApplication.subscriptionState) {
                        DispatchQueue.main.async {
                            
                            self?.specialOfferContainerView.isHidden = !Settings.current.isNeedToShowSpecialOffer
                            self?.containerStackView.reloadInputViews()
                            self?.contentScrollView.reloadInputViews()
                            
                        }
                    }
                }
            case .deleted:
                self?.applicationNotificationToken.invalidate()
            case .error(_):
                break
            }
        })
    }
}


/*
 MARK: - MFMailComposeViewControllerDelegate
 */
extension SettingsViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) {
            
        }
    }
}

