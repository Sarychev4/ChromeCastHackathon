//
//  LoadingViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 11.05.2022.
//
import UIKit
import Agregator
import DeviceKit
import Lottie

class LoadingViewController: BaseViewController {

    var didFinishAction: Closure!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.didFinishAction()
        }
    
        AgregatorManager.shared.start { [weak self] success in
            guard let _ = self else { return }
        }
    }
    
    
}
