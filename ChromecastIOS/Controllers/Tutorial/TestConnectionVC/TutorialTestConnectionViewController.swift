//
//  TestConnectionViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 26.04.2022.
//

import UIKit

class TutorialTestConnectionViewController: BaseViewController {

    @IBOutlet weak var continueInteractiveView: InteractiveView!
    @IBOutlet weak var continueLabel: DefaultLabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var didFinishAction: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        continueInteractiveView.cornerRadius = 8 * SizeFactor
        continueInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            ChromeCastService.shared.displayImage(with: URL(string: "http://risovach.ru/upload/2014/03/mem/s-dr-karoch_45066550_orig_.jpeg")!)
            
            self.didFinishAction?()
        }
    }

}
