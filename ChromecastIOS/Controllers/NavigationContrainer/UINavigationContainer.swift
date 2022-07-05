//
//  UINavigationController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 19.04.2022.
//

import UIKit
import DeviceKit


class UINavigationContainer: BaseViewController {

    @IBOutlet weak var contentView: UIView!
    
    
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
        
        edgeAnimatorForPushController = fromRightToCenterAnimator(currentVC)
        edgeAnimatorForPushController?.startAnimation()
        
        addRecognizerOnViewOfController(currentVC)
  
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
        }, completion: { (finished) in
            // self.currentViewController!.remove()
            controllerThatWillBeDeleted.remove()
            self.view.isUserInteractionEnabled = true
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

