//
//  DefaultNavigationController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 25.04.2022.
//

import UIKit

class DefaultNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        isNavigationBarHidden = false //temp as
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

}
