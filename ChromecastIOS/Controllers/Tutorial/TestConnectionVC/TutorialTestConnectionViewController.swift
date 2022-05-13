//
//  TestConnectionViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 26.04.2022.
//

import UIKit
import Agregator

class TutorialTestConnectionViewController: BaseViewController {

    deinit {
        print(">>> deinit TutorialTestConnectionViewController")
    }
    
    @IBOutlet weak var continueInteractiveView: InteractiveView!
    @IBOutlet weak var continueLabel: DefaultLabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var didFinishAction: (() -> ())?
    var source: String!
    var nameForEvents: String {
        return "Test connection screen"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AgregatorLogger.shared.log(eventName: "Tutorial_shown",
                                   parameters: ["Tutorial Step": nameForEvents, "Source": source])
        
        continueInteractiveView.cornerRadius = 8 * SizeFactor
        continueInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            ChromeCastService.shared.displayImage(with: URL(string: "http://risovach.ru/upload/2014/03/mem/s-dr-karoch_45066550_orig_.jpeg")!)
            self.didFinishAction?()
        }
        
        /*
         */
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForegroundAction),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
        
        /*
         */
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func willEnterForegroundAction() {
        AgregatorLogger.shared.log(eventName: "Tutorial_shown",
                                   parameters: ["Tutorial Step": nameForEvents, "Source": "Launch"])
    }

}
