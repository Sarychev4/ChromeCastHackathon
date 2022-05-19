//
//  YouTubeViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 21.04.2022.
//

import UIKit

class YouTubeViewController: BaseViewController {

    deinit {
        print(">>> deinit YouTubeViewController")
    }
    
    @IBOutlet weak var navigationBarShadowView: DropShadowView!
    @IBOutlet weak var backInteractiveView: InteractiveView!
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    private var navigationBarAnimator: UIViewPropertyAnimator?
    private var animator: ScrollViewAnimator?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        let youTubeCell = UINib(nibName: YouTubeCell.Identifier, bundle: .main)
        tableView.register(youTubeCell, forCellReuseIdentifier: YouTubeCell.Identifier)
        
        let suggestionCell = UINib(nibName: SuggestionCell.Identifier, bundle: .main)
        tableView.register(suggestionCell, forCellReuseIdentifier: SuggestionCell.Identifier)
        
        
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.navigation?.popViewController(self, animated: true)
        }
        
        connectInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.presentDevices(postAction: nil)
        }
        
    }
    
    private func presentDevices(postAction: (() -> ())?) {
        let controller = ListDevicesViewController()
        controller.canDismissOnPan = true
        controller.isInteractiveBackground = false
        controller.grabberState = .inside
        controller.grabberColor = UIColor.black.withAlphaComponent(0.8)
        controller.modalPresentationStyle = .overCurrentContext
        controller.didFinishAction = {  [weak self] in
            guard let _ = self else { return }
            postAction?()
        }
        present(controller, animated: false, completion: nil)
    }

}

extension YouTubeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: YouTubeCell.Identifier, for: indexPath) as! YouTubeCell
        return cell
    }
    
    
}

extension YouTubeViewController: UIScrollViewDelegate {
    private func setupNavigationAnimations() {
        navigationBarShadowView.alpha = 0
        navigationBarAnimator = UIViewPropertyAnimator(duration: 1.0, curve: .easeIn, animations: { [weak self] in
            guard let self = self else { return }
            self.navigationBarShadowView.alpha = 1
        })
        animator = ScrollViewAnimator(minAnchor: 0, maxAnchor: 50, animator: navigationBarAnimator!)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPosition = scrollView.contentOffset.y + scrollView.contentInset.top
        animator?.handleAnimation(with: currentPosition)
    }
}

extension YouTubeViewController: UISearchBarDelegate {
    
}

