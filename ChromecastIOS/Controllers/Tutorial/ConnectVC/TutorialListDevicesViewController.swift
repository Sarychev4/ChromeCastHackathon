//
//  TutorialListDevicesViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 26.04.2022.
//

import UIKit

class TutorialListDevicesViewController: AFFloatingPanelViewController {

    @IBOutlet weak var testView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    
    var didFinishAction: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let cellView = DeviceCellView()
        
        stackView.addArrangedSubview(cellView)
        stackView.reloadInputViews()
    }

}
