//
//  SettingsViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 20.04.2022.
//

import UIKit

class MirrorViewController: UIViewController {

    @IBOutlet weak var showHideInteractiveView: InteractiveView!
    @IBOutlet weak var showHideImageView: UIImageView!
    @IBOutlet weak var qualityContainer: UIStackView!
    
    private var isHide = true
    override func viewDidLoad() {
        super.viewDidLoad()
        
        qualityContainer.isHidden = true

        showHideInteractiveView.didTouchAction = {
            if self.qualityContainer.isHidden == true {
                self.qualityContainer.isHidden = false
                self.showHideImageView.image = UIImage(named: "hide")
            } else {
                self.qualityContainer.isHidden = true
                self.showHideImageView.image = UIImage(named: "show")
            }
        }
    }

}
