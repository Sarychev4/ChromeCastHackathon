//
//  YouTubeViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 21.04.2022.
//

import UIKit
//import Player
import XCDYouTubeKit_kbexdev
import GoogleCast
import SwiftUI
import RealmSwift
import ZMJTipView

enum PlaybackState {
    case playing
    case paused
    case stopped
}

class YouTubeViewController: BaseViewController {
    
    deinit {
        print(">>> deinit YouTubeViewController")
    }
    
    @IBOutlet weak var navigationBarShadowView: DropShadowView!
    @IBOutlet weak var backInteractiveView: InteractiveView!
    
    @IBOutlet weak var resumeVideoButton: ResumeVideoView!
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var emptyImageView: UIImageView!
    
    @IBOutlet weak var searchTip: DefaultLabel!
    
    private var videos: [YoutubeItem] = []
    private var suggestions: [String] = []
    private var pageToken: String?
    private var selectedIndex: Int = -1
    private var lastSuccessQuery: String?
    private var isLoading = false
    private var currentVideo: XCDYouTubeVideo?

    private var isTipWasShown = false
    private var tipView: ZMJTipView?
    
    private var navigationBarAnimator: UIViewPropertyAnimator?
    private var animator: ScrollViewAnimator?
    
    private var playerStateNotificationToken: NotificationToken?
    private var state: PlaybackState?
    
    private var isSuggestionsOnView: Bool {
        guard let searchText = searchBar.text, searchText.isEmpty == false, suggestions.count > 0 else { return false }
        return true
    }
    
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
//            ChromeCastService.shared.stopWebApp()
            self.tipView?.isHidden = true
            self.navigation?.popViewController(self, animated: true)
        }
        
        resumeVideoButton.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.tipView?.isHidden = true
            ChromeCastService.shared.showDefaultMediaVC()
        }
        
        
        connectInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.presentDevices(postAction: nil)
        }
        
        /*
         */

        
        if let data = UserDefaults.standard.youtubeLastResponse,
           let array = try? JSONDecoder().decode([YoutubeItem].self, from: data), array.count > 0 {
            videos = array
        }
        
        searchBar.searchTextField.textColor = UIColor(named: "labelColorDark")
        
        tableView.contentInset.top = 20
        tableView.reloadData()
        
        setupPlayerStateObserver()
        showHideResumeButton()
        
        searchTip.isHidden = true
        if videos.isEmpty {
            searchTip.isHidden = false
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
    }
    
    private func showHideResumeButton() {
        let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
        guard let playerState = remoteMediaClient?.mediaStatus?.playerState.rawValue else {
            resumeVideoButton.isHidden = true
            return
        }
        if playerState == 0 || playerState == 1 {
            resumeVideoButton.isHidden = true
        } else {
            resumeVideoButton.isHidden = false
        }
    }
    
    private func setupPlayerStateObserver() {
        let realm = try! Realm()
        if let playerStateObj = realm.objects(PlayerState.self).first {
            playerStateNotificationToken = playerStateObj.observe { [weak self] changes in
                guard let self = self else { return }
                switch changes {
                case .change(let object, let properties):
                    for property in properties {
                        print(">>> PlayerStateObj state \(properties)")
                        print(">>> PlayerStateObj Property '\(property.name)' of object \(object) changed to '\(property.newValue!)'")
                        let newVal = property.newValue as? Int
                        
                        switch newVal {
                        case 1:
                            self.state = .stopped
                            self.tipView?.isHidden = true
                            self.selectedIndex = -1
                            self.tableView.reloadData()
                        case 2:
                            self.state = .playing
                        case 3:
                            self.state = .paused
                        default:
                            print("")
                        }
                    }
                case .error(let error):
                    print(">>> PlayerStateObj An error occurred: \(error)")
                case .deleted:
                    print(">>> PlayerStateObj was deleted.")
                }
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
        
        preferences.animating.dismissTransform = CGAffineTransform(translationX: 100, y: 0);
        preferences.animating.showInitialTransform = CGAffineTransform(translationX: 100, y: 0);
        preferences.animating.showInitialAlpha = 0;
        preferences.animating.showDuration = 1;
        preferences.animating.dismissDuration = 1;
        
        let title = NSLocalizedString("Common.ResumeVideo.Tip", comment: "")
        guard let tipView2 = ZMJTipView(text: title, preferences: preferences, delegate: nil) else { return }
        self.tipView = tipView2
        self.tipView?.show(animated: true, for: self.resumeVideoButton, withinSuperview: nil)
    }
    
    private func cellClicked(at index: Int) {
        self.tipView?.isHidden = true
        self.connectIfNeeded { [weak self] in
            guard let self = self else { return }
            if self.selectedIndex != index && self.state == .paused { //если новая ячейка и ничего не играет
                self.playVideo(at: index)
            } else if self.selectedIndex != index && self.state == .playing { //если новая ячейка и видео уже играет
                self.playVideo(at: index)
            } else if self.selectedIndex == index && self.state == .paused { //eсли старая ячейка и ничего не играет
                ChromeCastService.shared.showDefaultMediaVC()
            } else if self.selectedIndex == index && self.state == .playing { //eсли старая ячейка и видео уже играет
                ChromeCastService.shared.showDefaultMediaVC()
            } else {
                self.playVideo(at: index)
            }
        }
    }
    
    private func pauseVideo() {
        self.connectIfNeeded { [weak self] in
            guard let self = self else { return }
            ChromeCastService.shared.pauseVideo()
            self.state = .paused
        }
    }
    
    private func playVideo(at index: Int, resolution: ResolutionType? = nil) {
        self.connectIfNeeded { [weak self] in
            guard let self = self else { return }
            
            self.selectedIndex = index
            self.state = .playing
            self.tableView.reloadData()
            let item = self.videos[index]
            if let videoId = item.id?.videoID {
                XCDYouTubeClient.default().getVideoWithIdentifier(videoId) { [weak self] (video, error) in
                    guard let self = self, let video = video else { return }
                    self.currentVideo = video
                    let resolution = self.getBestQuality(for: video)
                    if let downloadUrl = video.streamURLs[resolution.youtubeQuality],
                       let urlString = item.snippet?.thumbnails?.high?.url,
                       let previewImageUrl = URL(string: urlString) {
                        if self.isTipWasShown == false {
                            self.showTipView()
                            self.isTipWasShown = true
                        }
                        ChromeCastService.shared.displayVideo(with: downloadUrl, previewImage: previewImageUrl)
                        ChromeCastService.shared.showDefaultMediaVC()
                    }
                }
            }
        }
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
    
    private func getQualities(from video: XCDYouTubeVideo) -> [ResolutionType] {
        var result: [ResolutionType] = []
        
        if let _ = video.streamURLs[ResolutionType.low.youtubeQuality] {
            result.append(.low)
        }
        
        if let _ = video.streamURLs[ResolutionType.medium.youtubeQuality] {
            result.append(.medium)
        }
        
        if let _ = video.streamURLs[ResolutionType.high.youtubeQuality] {
            result.append(.high)
        }
        return result
    }
    
    private func getBestQuality(for video: XCDYouTubeVideo) -> ResolutionType {
        if let _ = video.streamURLs[ResolutionType.high.youtubeQuality] {
            return .high
        } else if let _ = video.streamURLs[ResolutionType.medium.youtubeQuality] {
            return .medium
        } else if let _ = video.streamURLs[ResolutionType.low.youtubeQuality] {
            return .low
        }
        return .high
    }
    
    private func requestVideos(for text: String) {
        guard isLoading == false else { return }
        isLoading = true
        if pageToken == nil {
            videos.removeAll()
        }
        activityIndicator.startAnimating()
        WebMediaSearchManager.youtubeVideoSearch(text, pageToken: pageToken) { [weak self] response in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.isLoading = false
            self.pageToken = response?.nextPageToken
            if let page = response?.items {
                self.videos += page
            }
            
            self.tableView.reloadData()
            
            UserDefaults.standard.youtubeLastResponse = try? JSONEncoder().encode(self.videos)
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
        if isSuggestionsOnView {
            emptyImageView.isHidden = true
            searchTip.isHidden = true
            return suggestions.count
        }
        emptyImageView.isHidden = videos.count > 0 || isLoading == true
        
        return videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSuggestionsOnView {
            let cell = tableView.dequeueReusableCell(withIdentifier: SuggestionCell.Identifier, for: indexPath) as! SuggestionCell
            cell.suggestionLabel.text = suggestions[indexPath.row]
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: YouTubeCell.Identifier, for: indexPath) as! YouTubeCell
            let item = videos[indexPath.row]
            cell.sectionNameView.isHidden = true
            cell.videoDescLabel.text = item.snippet?.title
            cell.channelNameLabel.text = item.snippet?.channelTitle
            let playPauseImage = selectedIndex == indexPath.row ? UIImage(named: "PausePlayerIcon") : UIImage(named: "PlayPlayerIcon")
            cell.playButtonIcon.image = playPauseImage
            if let urlString = item.snippet?.thumbnails?.high?.url,
               let url = URL(string: urlString) {
                cell.videoImage.kf.setImage(with: url, options: [.cacheMemoryOnly, .transition(.fade(0.3))])
            }
            cell.didPlayTap = { [weak self] in
                guard let self = self else { return }
                //temp as
                self.cellClicked(at: indexPath.row)
                //                self.playVideo(at: indexPath.row)
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSuggestionsOnView {
            let suggestionText = suggestions[indexPath.row]
            searchBar.text = suggestionText
            suggestions.removeAll()
            pageToken = nil
            requestVideos(for: suggestionText)
            searchBar.resignFirstResponder()
            tableView.reloadData()
        }
    }
    
}


extension YouTubeViewController: UISearchBarDelegate {
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        if text == "" {
            self.searchBar.endEditing(true)
        } else {
            pageToken = nil
            requestVideos(for: text)
            suggestions.removeAll()
            selectedIndex = -1
            tableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        if text == "" {
            self.searchBar.endEditing(true)
        } else {
            pageToken = nil
            requestVideos(for: text)
            suggestions.removeAll()
            self.searchBar.endEditing(true)
            selectedIndex = -1
            tableView.reloadData()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let text = searchBar.text else { return }
        if text != "" {
            AutoComplete.getQuerySuggestions(text) { [weak self] (result, error) in
                guard let self = self else { return }
                self.suggestions.removeAll()
                if let result = result {
                    self.suggestions.append(contentsOf: result)
                }
                self.tableView.reloadData()
            }
        }
    }
    
}

