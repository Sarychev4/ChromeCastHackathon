//
//  AlertViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 27.04.2022.
//

import UIKit

class AlertViewController: BaseViewController {

    @IBOutlet weak var darkBackgroundView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: DefaultLabel!
    @IBOutlet weak var subtitleLabel: DefaultLabel!
    @IBOutlet weak var continueLabel: DefaultLabel!
    
    @IBOutlet weak var continueInteractiveView: InteractiveView!
    private var alertTitle: String?
    private var alertSubtitle: String?
    private var continueAction: String?
    
    var continueClicked: (() -> ())?
    
    init(alertTitle: String?, alertSubtitle: String?, continueAction: String?){
        self.alertTitle = alertTitle
        self.alertSubtitle = alertSubtitle
        self.continueAction = continueAction
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.clipsToBounds = true
        containerView.cornerRadius = 14
        
        titleLabel.text = alertTitle
        subtitleLabel.text = alertSubtitle
        continueLabel.text = continueAction
        
        
        continueInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.continueClicked?()
        }
     
    }
    
    func present(from parent: UIViewController) {
        modalPresentationStyle = .overCurrentContext
        parent.present(self, animated: false, completion:  {
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self = self else { return }
                self.darkBackgroundView.alpha = 0
                UIView.animate(withDuration: 0.2) {
                    self.darkBackgroundView.alpha = 0.5
                } completion: { success in
                    
                }

                self.containerView.alpha = 0
                UIView.animate(withDuration: 0.4) {
                    self.containerView.alpha = 1
                } completion: { success in
                    
                }
            }
        })
    }
    
    func dismiss() {
        UIView.animate(withDuration: 0.2) {
            self.containerView.alpha = 0
        } completion: { success in
            self.dismiss(animated: false, completion: nil)
        }
    }
    
}
