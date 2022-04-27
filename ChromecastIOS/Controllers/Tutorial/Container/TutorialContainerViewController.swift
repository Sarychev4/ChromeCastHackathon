//
//  TutorialContainerViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 25.04.2022.
//
/*
 Model               Width  Height

 iPhone 13 Pro Max    428    926
 iPhone 12 Pro Max    428    926
 
 iPhone 11 Pro Max    414    896
 iPhone 11            414    896
 iPhone XR            414    896
 iPhone XS Max        414    896
 
 iPhone 7 Plus        476    847
 iPhone 6s Plus       476    847
 iPhone 6 Plus        476    847
 
 iPhone 13            390    844
 iPhone 13 Pro        390    844
 iPhone 12            390    844
 iPhone 12 Pro        390    844
 
 
 iPhone 13 mini       375    812
 iPhone 12 mini       375    812
 iPhone 11 Pro        375    812
 iPhone XS            375    812
 iPhone X             375    812
 
 iPhone 8 Plus        414    736

 iPhone SE 2nd gen    375    667
 iPhone 8             375    667
 iPhone 7             375    667
 iPhone 6s            375    667
 iPhone 6             375    667
 
 iPhone SE 1st gen    320    568
 iPhone 5             320    568
 
 iPhone 4             320    480
 
 */
import UIKit
import AdvancedPageControl
import Reachability

class TutorialContainerViewController: BaseViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var pageContainerView: AdvancedPageControlView!
    
    var didFinishAction: (() -> ())?
    var viewControllers: [UIViewController] = []
    var currentViewController: UIViewController!
    
    private var currentPage: Int = 0
    
    //MARK: - CONTROLLERS
    
    private var welcomeController: TutorialWelcomeViewController! {
        let controller = TutorialWelcomeViewController()
        controller.didFinishAction = { [weak self] in
            guard let self = self else { return }
            self.pushViewController(self.connectController)
//            self.pushViewController(self.accessToNetworkController)
        }
        return controller
    }
    
    private var accessToNetworkController: TutorialAccessToNetworkViewController! {
        let controller = TutorialAccessToNetworkViewController()
        controller.didFinishAction = { [weak self] in
            guard let self = self else { return }
            self.pushViewController(self.wifiController)
        }
        return controller
    }
    
    private var wifiController: TutorialWifiViewController! {
        let controller = TutorialWifiViewController()
        controller.didFinishAction = { [weak self] in
            guard let self = self else { return }
            self.pushViewController(self.connectController)
        }
        return controller
    }
    
    private var connectController: TutorialConnectViewController! {
        let controller = TutorialConnectViewController()
        controller.didFinishAction = { [weak self] in
            guard let self = self else { return }
            self.pushViewController(self.testConnectionController)
        }
        return controller
    }
    
    private var testConnectionController: TutorialTestConnectionViewController! {
        let controller = TutorialTestConnectionViewController()
        controller.didFinishAction = { [weak self] in
            guard let self = self else { return }
            self.pushViewController(self.previewImageController)
        }
        return controller
    }
    
    private var previewImageController: TutorialPreviewImageViewController! {
        let controller = TutorialPreviewImageViewController()
        controller.didFinishAction = { [weak self] in
            guard let self = self else { return }
            self.pushViewController(self.everythingReadyController)
        }
        return controller
    }
    
    private var everythingReadyController: TutorialEverythingReadyViewController! {
        let controller = TutorialEverythingReadyViewController()
        controller.didFinishAction = { [weak self] in
            guard let self = self else { return }
            self.pushViewController(self.ratingStarsController)
        }
        return controller
    }
    
    private var ratingStarsController: TutorialRatingStarsViewController! {
        let controller = TutorialRatingStarsViewController()
        controller.didFinishAction = { [weak self] in
            guard let self = self else { return }
            self.pushViewController(self.thankYouController)
        }
        return controller
    }
    
    private var thankYouController: TutorialThankYouViewController! {
        let controller = TutorialThankYouViewController()
        controller.didFinishAction = { [weak self] in
            guard let self = self else { return }
            self.didFinishAction?()
        }
        return controller
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setRootViewController(welcomeController)
        setupPageController()
    }
    
    
    private func pushViewController(_ pushVC: UIViewController) {
        addController(pushVC, container: stackView)
        
        currentViewController.beginAppearanceTransition(false, animated: true)
        pushVC.beginAppearanceTransition(true, animated: true)
        
        currentPage += 1
        
        show(currentPage, animated: true, onComplete: { [weak self] in
            guard let self = self else { return }
            self.currentViewController.endAppearanceTransition()
            pushVC.endAppearanceTransition()
            self.currentViewController = pushVC
        })
    }
    
    private func popViewController() {
        currentViewController.beginAppearanceTransition(false, animated: true)
        
        currentPage -= 1
        
        let leftVC = viewControllers[currentPage]
        leftVC.beginAppearanceTransition(true, animated: true)
        
        show(currentPage, animated: true, onComplete: { [weak self] in
            guard let self = self else { return }
            self.currentViewController.endAppearanceTransition()
            leftVC.endAppearanceTransition()
            self.removeController(self.currentViewController)
            self.currentViewController = leftVC
        })
    }
    
    private func show(_ page: Int, animated: Bool, onComplete: (() -> ())?) {
        guard currentPage < viewControllers.count else { return }
        
        let width = UIScreen.main.bounds.width
        let x = width * CGFloat(currentPage)
        
        scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: animated)
        pageContainerView.setPage(page)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            onComplete?()
        }
    }
    
    private func setRootViewController(_ rootVC: UIViewController) {
        currentViewController = rootVC
        rootVC.beginAppearanceTransition(true, animated: false)
        addController(rootVC, container: stackView)
        rootVC.endAppearanceTransition()
    }
    
    private func setupPageController() {
        let pagesCount = 9
        pageContainerView.drawer = ExtendedDotDrawer(numberOfPages: pagesCount,
                                                     height: 8,
                                                     width: 8,
                                                     space: 8,
                                                     raduis: 4,
                                                     currentItem: 0,
                                                     indicatorColor: UIColor(hexString: "007AFF"),dotsColor: UIColor(hexString: "ececec"))
    }

}

//MARK: -EXTENSION

extension TutorialContainerViewController {
    
    func addController(_ child: UIViewController, container: UIStackView) {
        addChild(child)
        child.view.frame = UIScreen.main.bounds
        child.view.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width).isActive = true
        container.addArrangedSubview(child.view)
        child.didMove(toParent: self)
        
        viewControllers.append(child)
    }
    
    func removeController(_ child: UIViewController) {
        child.willMove(toParent: nil)
        child.view.removeFromSuperview()
        child.removeFromParent()
        viewControllers.removeAll(where: { $0 == child })
    }
}
