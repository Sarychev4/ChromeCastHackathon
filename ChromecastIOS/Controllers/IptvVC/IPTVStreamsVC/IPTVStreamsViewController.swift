//
//  IPTVStreamsViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 11.05.2022.
//

import UIKit
import RealmSwift
import GoogleCast
import ZMJTipView

class IPTVStreamsViewController: BaseViewController {

    deinit {
        print(">>> deinit IPTVStreamsViewController")
    }
    
    @IBOutlet weak var navigationBarShadowView: DropShadowView!
    @IBOutlet weak var backInteractiveView: InteractiveView!
    @IBOutlet weak var navigationTitleLabel: DefaultLabel!
    
    @IBOutlet weak var resumeVideoInteractiveView: ResumeVideoView!
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    private var state: PlaybackState?
    private var selectedIndex: Int = -1
    
    private var isTipWasShown = false
    private var tipView: ZMJTipView?
    
    var playlistId: String!
    
    private var playlist: PlaylistM3U8?
    private var streams: Results<IPTVStream>?
    private var navigationBarAnimator: UIViewPropertyAnimator?
    private var animator: ScrollViewAnimator?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        let cell = UINib(nibName: IPTVStreamCell.Identifier, bundle: .main)
        tableView.register(cell, forCellReuseIdentifier: IPTVStreamCell.Identifier)
        
        /*
         */
        
        playlist = IPTVManager.realm.object(ofType: PlaylistM3U8.self, forPrimaryKey: playlistId)
        
        /*
         */
        
        streams = playlist?.streams.sorted(byKeyPath: #keyPath(IPTVStream.name), ascending: true)
        
        /*
         */
        
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.navigation?.popViewController(self, animated: true)
        }
        
        resumeVideoInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.tipView?.isHidden = true
            ChromeCastService.shared.showDefaultMediaVC()
        }
        
        connectInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.presentDevices(postAction: nil)
        }
        
        navigationTitleLabel.text = playlist?.name
        
        setupNavigationAnimations()
        searchBar.searchTextField.textColor = UIColor(named: "labelColorDark")
        
        setupPlayerStateObserver()
        showHideResumeButton()
    }
    
    private func showHideResumeButton() {
        let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
        guard let playerState = remoteMediaClient?.mediaStatus?.playerState.rawValue else {
            resumeVideoInteractiveView.isHidden = true
            return
        }
        if playerState == 0 || playerState == 1 {
            resumeVideoInteractiveView.isHidden = true
        } else {
            resumeVideoInteractiveView.isHidden = false
        }
    }
    
    
    
    private func stopEditing() {
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
        }
        tableView.reloadData()
    }
    
    private func presentDevices(postAction: (() -> ())?) {
        let controller = ListDevicesViewController()
        controller.canDismissOnPan = true
        controller.isInteractiveBackground = true
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

extension IPTVStreamsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return streams?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: IPTVStreamCell.Identifier, for: indexPath) as! IPTVStreamCell
        if let stream = streams?[indexPath.row] {
            cell.setup(with: stream)
            cell.didTouchAction = { [weak self] in
                guard let self = self else { return }
                self.didSelectCell(at: indexPath)
            }
        }
        return cell
    }
    
    func didSelectCell(at indexPath: IndexPath) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let index = indexPath.row
            connectIfNeeded { [weak self] in
                guard let self = self, let stream = self.streams?[indexPath.row] else { return }
                guard let streamUrl = URL(string: stream.url) else { return }
                if self.isTipWasShown == false {
                    self.resumeVideoInteractiveView.isHidden = false
                    self.showTipView()
                    self.isTipWasShown = true
                }
                
                if self.selectedIndex != index && self.state == .paused { //если новая ячейка и ничего не играет
                    self.selectedIndex = index
                    self.state = .playing
                    ChromeCastService.shared.displayVideo(with: streamUrl)
                    ChromeCastService.shared.showDefaultMediaVC()
                } else if self.selectedIndex != index && self.state == .playing { //если новая ячейка и видео уже играет
                    self.selectedIndex = index
                    self.state = .playing
                    ChromeCastService.shared.displayVideo(with: streamUrl)
                    ChromeCastService.shared.showDefaultMediaVC()
                } else if self.selectedIndex == index && self.state == .paused { //eсли старая ячейка и ничего не играет
                    ChromeCastService.shared.showDefaultMediaVC()
                } else if self.selectedIndex == index && self.state == .playing { //eсли старая ячейка и видео уже играет
                    ChromeCastService.shared.showDefaultMediaVC()
                } else {
                    self.selectedIndex = index
                    self.state = .playing
                    ChromeCastService.shared.displayVideo(with: streamUrl)
                    ChromeCastService.shared.showDefaultMediaVC()
                }
                
            }
        
    }
    
    private func setupPlayerStateObserver() {
        ChromeCastService.shared.observePlayerState { state in
            switch state {
            case 1:
                self.state = .stopped
                self.tipView?.isHidden = true
                self.selectedIndex = -1
                
            case 2:
                self.state = .playing
            case 3:
                self.state = .paused
            case 0:
                self.tipView?.isHidden = true
            default:
                print("")
            }
        }
    }
    
    private func showTipView() {
        let preferences = ZMJPreferences()
        preferences.drawing.font = UIFont.systemFont(ofSize: 14)
        preferences.drawing.textAlignment = .center
        preferences.drawing.backgroundColor = UIColor(hexString: "FBBB05")
        preferences.positioning.maxWidth = 130
//        preferences.positioning.bubbleVInset = 34
        preferences.drawing.arrowPosition = .top
        preferences.drawing.arrowHeight = 0
        
        preferences.animating.dismissTransform = CGAffineTransform(translationX: 100, y: 0);
        preferences.animating.showInitialTransform = CGAffineTransform(translationX: 100, y: 0);
        preferences.animating.showInitialAlpha = 0;
        preferences.animating.showDuration = 1;
        preferences.animating.dismissDuration = 1;
        
        let title = NSLocalizedString("Common.ResumeVideo.Tip", comment: "")
        guard let tipView2 = ZMJTipView(text: title, preferences: preferences, delegate: nil) else { return }
        self.tipView = tipView2
        self.tipView?.show(animated: true, for: self.resumeVideoInteractiveView, withinSuperview: nil)
    }
    
    private func connectIfNeeded(onComplete: Closure?) {
        guard GCKCastContext.sharedInstance().sessionManager.connectionState.rawValue != 2 else {
            onComplete?()
            return
        }
        presentDevices {
            onComplete?()
        }
    }
    
    
    
}

extension IPTVStreamsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        streams = playlist?.streams.sorted(byKeyPath: #keyPath(IPTVStream.name), ascending: true)
        if searchText.count > 0 {
            streams = streams?.filter("\(#keyPath(IPTVStream.name)) CONTAINS[cd] '\(searchText)'")
        }
        tableView.reloadData()
    }
}


extension IPTVStreamsViewController: UIScrollViewDelegate {
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
