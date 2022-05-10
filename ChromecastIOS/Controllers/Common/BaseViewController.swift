//
//  BaseViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 19.04.2022.
//

import Foundation
import UIKit
import MBProgressHUD

open class BaseViewController: UIViewController {

    /*
     */
    
    @IBOutlet var constraintsToScale: [NSLayoutConstraint]?
    @IBOutlet var stackViewsToScale: [UIStackView]?
    
    @IBInspectable open var isAutomaticalyResizeEnabled: Bool = true
    
    /*
     MARK: -
     */
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        /*
         */
        
        view.clipsToBounds = true
        
        /*
         */
        
        if isAutomaticalyResizeEnabled == true {
            resizeAllConstraints(for: view)
            resizeAllStackViews(for: view)
        } else {
            if let constraints = constraintsToScale {
                for constraint in constraints {
                    constraint.constant = round(constraint.constant * SizeFactor)
                }
            }
            
            if let stackViews = stackViewsToScale {
                for stackView in stackViews {
                    stackView.spacing = round(stackView.spacing * SizeFactor)
                }
            }
        }
    }
    
    /*
     MARK: -
     */
    
    func resizeAllConstraints(for view: UIView) {
        for constraint in view.constraints {
            constraint.constant = round(constraint.constant * SizeFactor)
        }
        
        for subview in view.subviews {
            resizeAllConstraints(for: subview)
        }
    }
    
    func resizeAllStackViews(for view: UIView) {
        for subview in view.subviews {
            if let stackView = subview as? UIStackView {
                stackView.spacing = round(stackView.spacing * SizeFactor)
            }
            
            resizeAllStackViews(for: subview)
        }
    }
    
    /*
     MARK: -
     */
    
    override open var prefersStatusBarHidden: Bool {
        get {
            return false
        }
    }
    
    override open var shouldAutorotate: Bool {
        get {
            return false
        }
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .portrait
        }
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    func checkInternetConnection(with completeBlock: @escaping Closure) {

        let HUD = MBProgressHUD.showAdded(to: view, animated: true)
        DataManager.shared.checkConnection { [weak self] status in
            HUD.hide(animated: true)

            if status == .success {
                completeBlock()
            } else {
                let alertTitle = NSLocalizedString("Reachabality.NoInternet.Title", comment: "")
                let alertMessage = NSLocalizedString("Reachabality.NoInternet.Message", comment: "")
                let OKButtonTitle = NSLocalizedString("Reachabality.NoInternet.OKButton.Title", comment: "")
                let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                let OKAction = UIAlertAction(title: OKButtonTitle, style: .default) { action in

                }

                alertController.addAction(OKAction)
                self?.present(alertController, animated: true, completion: nil)
            }
        }
    }

}
