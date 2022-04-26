//
//  TutorialThankYouViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 26.04.2022.
//

import UIKit

class TutorialThankYouViewController: BaseViewController {

    @IBOutlet weak var continueInteractiveView: InteractiveView!
    @IBOutlet weak var continueLabel: DefaultLabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var didFinishAction: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        continueInteractiveView.cornerRadius = 8 * SizeFactor
        continueInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.didFinishAction?()
        }
    }
}
