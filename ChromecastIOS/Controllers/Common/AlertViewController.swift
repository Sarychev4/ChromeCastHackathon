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
    
    @IBOutlet weak var yesNoContainer: UIStackView!
    
    @IBOutlet weak var noInteractiveLabel: InteractiveLabel!
    @IBOutlet weak var yesInteractiveLabel: InteractiveLabel!
  
    private var alertTitle: String?
    private var alertSubtitle: String?
    
    private var continueAction: String?
    private var leftAction: String?
    private var rightAction: String?
    
    var continueClicked: (() -> ())?
    var noClicked: (() -> Void)?
    var yesClicked: (() -> Void)?
    
    init(alertTitle: String?, alertSubtitle: String?, continueAction: String?, leftAction: String?, rightAction: String?){
        self.alertTitle = alertTitle
        self.alertSubtitle = alertSubtitle
        self.continueAction = continueAction
        self.leftAction = leftAction
        self.rightAction = rightAction
        
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
        noInteractiveLabel.text = leftAction
        yesInteractiveLabel.text = rightAction
        
        if continueAction == nil {
            continueInteractiveView.isHidden = true
        } else {
            yesNoContainer.isHidden = true
        }
        
        yesInteractiveLabel.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.yesClicked?()
        }
        
        noInteractiveLabel.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.noClicked?()
        }
        
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
