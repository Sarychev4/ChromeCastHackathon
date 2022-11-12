//
//  LoadingViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 11.05.2022.
//
import UIKit
import DeviceKit
import Lottie

class LoadingViewController: BaseViewController {

    @IBOutlet weak var animationView: AnimationView!
    var didFinishAction: Closure!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        animationView.backgroundBehavior = .pauseAndRestore
//        animationView.contentMode = .scaleAspectFit
//
//        animationView.play(){ [weak self] (finished) in
//            guard let self = self else { return }
//            if finished == true {
//                self.didFinishAction()
//            }
//
//        }
        
       
    } 
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.didFinishAction()
    }
    
}
