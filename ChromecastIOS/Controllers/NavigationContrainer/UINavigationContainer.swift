//
//  UINavigationController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 19.04.2022.
//

import UIKit
import DeviceKit
import Agregator


class UINavigationContainer: BaseViewController {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var tabBarView: UIView!
    
    @IBOutlet weak var castInteractiveView: InteractiveView!
    @IBOutlet weak var castIconImageView: UIImageView!
    @IBOutlet weak var castLabel: DefaultLabel!
    
    @IBOutlet weak var channelsInteractiveView: InteractiveView!
    @IBOutlet weak var channelsIconImageView: UIImageView!
    @IBOutlet weak var channelsLabel: DefaultLabel!
    
    @IBOutlet weak var whiteboardInteractiveView: InteractiveView!
    @IBOutlet weak var whiteboardIconImageView: UIImageView!
    @IBOutlet weak var whiteboardLabel: DefaultLabel!
    
    @IBOutlet weak var settingsInteractiveView: InteractiveView!
    @IBOutlet weak var settingsIconImageView: UIImageView!
    @IBOutlet weak var settingLabel: DefaultLabel!
    
    var currentViewController: UIViewController?
    var previousViewController: UIViewController?
    
    var viewControllers: [UIViewController] = []
    var rootViewController: UIViewController?
    
    fileprivate var edgeAnimatorForPopController: UIViewPropertyAnimator?
    fileprivate var edgeAnimatorForPushController: UIViewPropertyAnimator?
    fileprivate var shouldCompleteTransition = false
    
    public init(rootViewController: UIViewController){
        self.rootViewController = rootViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        add(rootViewController!, container: contentView)
        viewControllers.append(rootViewController!)
        
        setupTabBar()
        
    }
    
    func setupTabBar() {
        
        castInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            
            if self.rootViewController != MainViewController() {
                self.removeAllSubviewsIn(container: self.contentView)
                let mainVC = MainViewController()
                self.rootViewController = mainVC
                self.add(mainVC, container: self.contentView)
                self.viewControllers.removeAll()
                self.viewControllers.append(mainVC)
            }
           
            self.castIconImageView.tintColor = UIColor.systemBlue
            self.castLabel.textColor = UIColor.systemBlue
            
            self.channelsIconImageView.tintColor = UIColor(named: "MySubTitleColor")
            self.channelsLabel.textColor = UIColor(named: "MySubTitleColor")
            
            self.whiteboardIconImageView.tintColor = UIColor(named: "MySubTitleColor")
            self.whiteboardLabel.textColor = UIColor(named: "MySubTitleColor")
            
            self.settingsIconImageView.tintColor = UIColor(named: "MySubTitleColor")
            self.settingLabel.textColor = UIColor(named: "MySubTitleColor")
        }
        
        channelsInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            
            if self.rootViewController != ChannelsViewController() {
                self.removeAllSubviewsIn(container: self.contentView)
                let channelsVC = ChannelsViewController()
                self.rootViewController = channelsVC
                self.add(channelsVC, container: self.contentView)
                self.viewControllers.removeAll()
                self.viewControllers.append(channelsVC)
            }
            
            self.castIconImageView.tintColor = UIColor(named: "MySubTitleColor")
            self.castLabel.textColor = UIColor(named: "MySubTitleColor")
            
            self.channelsIconImageView.tintColor = UIColor.systemBlue
            self.channelsLabel.textColor = UIColor.systemBlue
            
            self.whiteboardIconImageView.tintColor = UIColor(named: "MySubTitleColor")
            self.whiteboardLabel.textColor = UIColor(named: "MySubTitleColor")
            
            self.settingsIconImageView.tintColor = UIColor(named: "MySubTitleColor")
            self.settingLabel.textColor = UIColor(named: "MySubTitleColor")
            
        }
        
        whiteboardInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            
            if self.rootViewController != ChannelsViewController() {
                self.removeAllSubviewsIn(container: self.contentView)
                let wbVC = WhiteboardViewController()
                self.rootViewController = wbVC
                self.add(wbVC, container: self.contentView)
                self.viewControllers.removeAll()
                self.viewControllers.append(wbVC)
            }
            
            self.castIconImageView.tintColor = UIColor(named: "MySubTitleColor")
            self.castLabel.textColor = UIColor(named: "MySubTitleColor")
            
            self.channelsIconImageView.tintColor = UIColor(named: "MySubTitleColor")
            self.channelsLabel.textColor = UIColor(named: "MySubTitleColor")
            
            self.whiteboardIconImageView.tintColor = UIColor.systemBlue
            self.whiteboardLabel.textColor = UIColor.systemBlue
            
            self.settingsIconImageView.tintColor = UIColor(named: "MySubTitleColor")
            self.settingLabel.textColor = UIColor(named: "MySubTitleColor")
            
        }
        
        settingsInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            
            if self.rootViewController != ChannelsViewController() {
                self.removeAllSubviewsIn(container: self.contentView)
                let settingsVC = SettingsViewController()
                self.rootViewController = settingsVC
                self.add(settingsVC, container: self.contentView)
                self.viewControllers.removeAll()
                self.viewControllers.append(settingsVC)
            }
            
            
//            AgregatorLogger.shared.log(eventName: "Setting", parameters: ["Source": "Main_screen"])
//            let settingsViewController = SettingsViewController()
//            let navigationController = DefaultNavigationController(rootViewController: settingsViewController)
//            navigationController.modalPresentationStyle = .fullScreen
//            self.present(navigationController, animated: true, completion: nil)
            
            self.castIconImageView.tintColor = UIColor(named: "MySubTitleColor")
            self.castLabel.textColor = UIColor(named: "MySubTitleColor")
            
            self.channelsIconImageView.tintColor = UIColor(named: "MySubTitleColor")
            self.channelsLabel.textColor = UIColor(named: "MySubTitleColor")
            
            self.whiteboardIconImageView.tintColor = UIColor(named: "MySubTitleColor")
            self.whiteboardLabel.textColor = UIColor(named: "MySubTitleColor")
            
            self.settingsIconImageView.tintColor = UIColor.systemBlue
            self.settingLabel.textColor = UIColor.systemBlue
            
        }
        
    }
    
    /*
     */
    
    func pushViewController(_ controller: UIViewController, animated: UINavigationContainerTransionType) {
        
        previousViewController = viewControllers.last
        viewControllers.append(controller)
        currentViewController = viewControllers.last
        
        guard let currentVC = currentViewController else { return }
        
        view.isUserInteractionEnabled = false
        
        add(currentVC, container: contentView, frame: CGRect(x: +UIScreen.main.bounds.size.width, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        
//        add(currentVC, container: contentView, frame: CGRect(x: +UIScreen.main.bounds.size.width, y: 0, width: UIScreen.main.bounds.size.width, height: contentView.bounds.size.height))
        
        edgeAnimatorForPushController = fromRightToCenterAnimator(currentVC)
        edgeAnimatorForPushController?.startAnimation()
        
        addRecognizerOnViewOfController(currentVC)
        
        //temp as
        if controller.hidesBottomBarWhenPushed == true {
            tabBarView.isHidden = true
        }
  
    }
    
    func popViewController(_ controller: UIViewController, animated: Bool) {
        
        let controllerThatWillBeDeleted = controller
        
        viewControllers.removeLast()
        
        currentViewController = viewControllers.last

        if viewControllers.count >= 2 {
            previousViewController = viewControllers[viewControllers.count - 2]
        } else {
            previousViewController = viewControllers.first
        }

        view.isUserInteractionEnabled = false
        
        guard let currenVC = currentViewController else { return }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            controllerThatWillBeDeleted.view.frame.origin.x = +UIScreen.main.bounds.size.width
            currenVC.view.frame.origin.x = 0
            
        }, completion: { [weak self] (finished) in
            guard let self = self else { return }
            // self.currentViewController!.remove()
            controllerThatWillBeDeleted.remove()
            self.view.isUserInteractionEnabled = true
            
            //temp as
            if controller.hidesBottomBarWhenPushed == true {
                self.tabBarView.isHidden = false
            }
        })
        
        print(">>>UINavigationContainer", currenVC, currenVC.hidesBottomBarWhenPushed)
    }
    
    private func addRecognizerOnViewOfController(_ controller: UIViewController){
        let edgeRecognizer = UIScreenEdgePanGestureRecognizer()
        edgeRecognizer.edges = .left
        edgeRecognizer.addTarget(self, action: #selector(handleGesture(_:)))
        controller.view.addGestureRecognizer(edgeRecognizer)
    }
    
    private func fromCenterToRightAnimator(_ controller: UIViewController) -> UIViewPropertyAnimator{
        let animator = UIViewPropertyAnimator(duration:2, curve: .linear) {
            controller.view.frame.origin.x = +UIScreen.main.bounds.size.width
            
            guard let previousVC = self.previousViewController else { return }

            previousVC.view.frame.origin.x = 0//+UIScreen.main.bounds.size.width
        }
        
        animator.addCompletion { (finished) in
            if self.shouldCompleteTransition == true {
                self.popViewController(controller, animated: true)
            }
        }
        return animator
    }
    
    private func fromRightToCenterAnimator(_ controller: UIViewController) -> UIViewPropertyAnimator{
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
            controller.view.frame.origin.x = self.view.frame.origin.x
            
            guard let previousVC = self.previousViewController else { return }
        
            previousVC.view.frame.origin.x -= previousVC.view.frame.width
        }
        animator.addCompletion { [weak self] _ in
            self?.view.isUserInteractionEnabled = true
        }
        //animator.scrubsLinearly = false
        return animator
    }
    
    @objc private func handleGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        
        let translation = gestureRecognizer.translation(in: view.superview!)
        var progress = (abs(translation.x) / view.frame.size.width)
        progress = CGFloat(fminf(fmaxf(Float(progress), 0.0), 1.0))
        
        guard let currentVC = self.currentViewController else { return }
        
        switch gestureRecognizer.state {
        case .began:
            
            edgeAnimatorForPopController = fromCenterToRightAnimator(currentVC)
            
        case .changed:
            
            shouldCompleteTransition = progress > 0.28// процент от экрана
            
            edgeAnimatorForPopController?.fractionComplete = progress
            
        case .cancelled, .ended:
           
            if shouldCompleteTransition == false {
                edgeAnimatorForPopController?.isReversed = true
            }
            edgeAnimatorForPopController?.continueAnimation(withTimingParameters: nil, durationFactor: 0.1) // if durationFactor will be 0, animation will be long
            
        default:
            break
        }
    }
}


enum UINavigationContainerTransionType {
    
    case none
    case left
    //   case 'default'
    
}

