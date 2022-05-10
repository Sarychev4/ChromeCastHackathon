//
//  SubscriptionSpotsManager.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 28.04.2022.
//

import Agregator
import RealmSwift
import UIKit

protocol SubscriptionController: UIViewController {
    var spot: SubscriptionSpot! { get set }
    var didFinishAction: ClosureBool! { get set }
}

class SubscriptionSpotsManager {
    
    /*
     MARK: -
     */
    
    static let shared = SubscriptionSpotsManager()
     
    /*
     MARK: -
     */
    
    var subscriptionViewController: SubscriptionController?
    var specialOfferViewController: PremiumDiscountViewController?
    
    /*
     MARK: -
     */
    
    func initialize() {
    }
    
    func requestSpot(for spotTitle: String, with completeBlock: @escaping ClosureBool) {
        let realm = try! Realm()
        guard Settings.current.isIntroCompleted, subscriptionViewController == nil, specialOfferViewController == nil, let spot = realm.objects(SubscriptionSpot.self).filter("\(#keyPath(SubscriptionSpot.title)) == '\(spotTitle)'").first, spot.isEnabled == true, AgregatorApplication.current.subscriptionState == .none || AgregatorApplication.current.subscriptionState == .expired || AgregatorApplication.current.subscriptionState == .customTrialExpired else {
            completeBlock(true)
            return
        }
        
        /*
         */
        
        realm.beginWrite()
        
        spot.currentActionsCount += 1
        
        /*
         */
        
        func showSpot() {
            showViewController(for: spot, with: completeBlock)
        }
        
        if spot.currentActionsCount == spot.actionsCountToStart {
            showSpot()
        } else if (spot.currentActionsCount - spot.actionsCountToStart) > 0 && (spot.currentActionsCount - spot.actionsCountToStart) % (spot.actionsCountToSkipAfterStart + 1) == 0 {
            showSpot()
        } else {
            completeBlock(true)
        }
        
        try! realm.commitWrite()
    }
    
    private func showViewController(for spot: SubscriptionSpot, with completeBlock: @escaping ClosureBool) {
        
        if Settings.current.isNeedToShowSpecialOffer && spot.isSpecialOfferEnabled {
            specialOfferViewController = PremiumDiscountViewController()
            specialOfferViewController?.spot = spot
            specialOfferViewController?.source = spot.title

            let navigationController = DefaultNavigationController(rootViewController: specialOfferViewController!)
            navigationController.modalPresentationStyle = .fullScreen
            TopViewController?.present(navigationController, animated: true, completion: nil)

            specialOfferViewController!.didFinishAction = { [weak self, weak navigationController] success in
                navigationController?.dismiss(animated: true, completion: {
                    self?.specialOfferViewController = nil
                    completeBlock(success)
                })
            }
        } else {
            if let _ = spot.getValue(for: "second_button") {
                subscriptionViewController = PremuimLifeTimeViewController()
            } else {
//                subscriptionViewController = PremiumViewController()
            }
            subscriptionViewController!.spot = spot
            let navigationController = DefaultNavigationController(rootViewController: subscriptionViewController!)
            navigationController.modalPresentationStyle = .fullScreen

            if spot.presentationStyle == .modal {
                TopViewController?.present(navigationController, animated: true, completion: nil)
            } else if spot.presentationStyle == .fade {
                TopViewController?.addChild(subscriptionViewController!)
                subscriptionViewController!.view.alpha = 0
                TopViewController?.view.addSubview(subscriptionViewController!.view)
                subscriptionViewController!.view.bindToSuperview()

                UIView.animate(withDuration: 0.3) {
                    self.subscriptionViewController!.view.alpha = 1
                }
            }

            subscriptionViewController!.didFinishAction = { [weak self, weak navigationController] success in
                if spot.presentationStyle == .modal {
                    navigationController?.dismiss(animated: true, completion: {
                        self?.subscriptionViewController = nil
                        completeBlock(success)
                    })
                } else if spot.presentationStyle == .fade {
                    self?.subscriptionViewController?.view.removeFromSuperview()
                    self?.subscriptionViewController?.removeFromParent()
                    self?.subscriptionViewController = nil
                    completeBlock(success)
                }
            }
        }
    }
}
