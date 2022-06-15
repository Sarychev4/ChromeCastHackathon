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
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var emptyImageView: UIImageView!
    @IBOutlet weak var mediaControlView: MediaControlView!
    
    
    private var videos: [YoutubeItem] = []
    private var suggestions: [String] = []
    private var pageToken: String?
    private var selectedIndex: Int = -1
    private var lastSuccessQuery: String?
    private var isLoading = false
    private var currentVideo: XCDYouTubeVideo?
    private var videoProgressTimer: Timer?
    private var currentTime: TimeInterval = 0
    
    private var navigationBarAnimator: UIViewPropertyAnimator?
    private var animator: ScrollViewAnimator?
    
    private var state: PlaybackState? {
        didSet {
            if let state = state {
                if state == .playing {
                    mediaControlView.playButtonIcon.image = UIImage(named: "PauseIcon")
                } else if state == .paused  {
                    mediaControlView.playButtonIcon.image = UIImage(named: "PlayIcon")
                } else if state == .stopped {
                    currentTime = 0
                    mediaControlView.playButtonIcon.image = UIImage(named: "PlayIcon")
                }
            }
        }
    }
    
    private var isSuggestionsOnView: Bool {
        guard let searchText = searchBar.text, searchText.isEmpty == false, suggestions.count > 0 else { return false }
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mediaControlView.alpha = 0
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        let youTubeCell = UINib(nibName: YouTubeCell.Identifier, bundle: .main)
        tableView.register(youTubeCell, forCellReuseIdentifier: YouTubeCell.Identifier)
        
        let suggestionCell = UINib(nibName: SuggestionCell.Identifier, bundle: .main)
        tableView.register(suggestionCell, forCellReuseIdentifier: SuggestionCell.Identifier)
        
        
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            ChromeCastService.shared.stopWebApp()
            self.navigation?.popViewController(self, animated: true)
        }
        
        connectInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.presentDevices(postAction: nil)
        }
        
        /*
         */
        
        let sliderThumb = UIImage(named: "SliderThumb")!
        mediaControlView.progressView.setThumbImage(sliderThumb, for: .normal)
        mediaControlView.progressView.setThumbImage(sliderThumb, for: .highlighted)
        
        mediaControlView.prevInteractiveView.didTouchAction = { [weak self] in
            guard let self = self, self.selectedIndex > 1 else { return }
            self.playVideo(at: self.selectedIndex - 1)
        }
        
        mediaControlView.forwardInteractiveView.didTouchAction = { [weak self] in
            guard let self = self, self.selectedIndex < self.videos.count - 1 else { return }
            self.playVideo(at: self.selectedIndex + 1)
        }
        
        mediaControlView.playPauseInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            if self.state == .stopped || self.state == nil {
                self.playVideo(at: self.selectedIndex)
            } else if self.state == .paused {
                //temp
                //                DeviceManager.shared.mediaControlPlayVideo()
            } else if self.state == .playing {
                //temp
                //                DeviceManager.shared.mediaControlPauseVideo()
            }
            self.mediaControlView.playPauseInteractiveView.isEnabled = false
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
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    /*
     MARK: - Player Methods
     */
    
    private func cellClicked(at index: Int) {
        self.connectIfNeeded { [weak self] in
            guard let self = self else { return }
            print(">>>\(index)")
            print(">>>\(self.selectedIndex)")
            print(">>>\(self.state)")

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
                    //                        self.mediaControlView.alpha = 1
                    self.currentVideo = video
                    let resolution = self.getBestQuality(for: video)
                    if let downloadUrl = video.streamURLs[resolution.youtubeQuality],
                       let urlString = item.snippet?.thumbnails?.high?.url,
                       let previewImageUrl = URL(string: urlString) {
                        ChromeCastService.shared.displayVideo(with: downloadUrl, previewImage: previewImageUrl)
                        ChromeCastService.shared.showDefaultMediaVC()
                        self.startVideoProgressTimer()
                        self.mediaControlView.remainingTimeLabel.text = "\(video.duration.durationText)"
                        self.mediaControlView.playButtonIcon.image = UIImage(named: "PauseIcon")
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
    
    
    private func stopVideoProgressTimer() {
        videoProgressTimer?.invalidate()
        videoProgressTimer = nil
    }
    
    private func startVideoProgressTimer() {
        stopVideoProgressTimer()
        videoProgressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
            guard let self = self else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
                
                guard let currentTime = remoteMediaClient?.mediaStatus?.streamPosition else { return }
                //print(currentTime)
                
                if self.currentTime == 0 && currentTime > TimeInterval(2) {
                    // Это кейс когда переключили с одного видео на другой, а инфа устаревшая про предыдущее видео все еще доходит
                    return
                }
                self.mediaControlView.playPauseInteractiveView.isEnabled = true
                let videoDuration = Int(self.currentVideo?.duration ?? 0)
                
                if currentTime > 0 {
                    
                    if currentTime != self.currentTime {
                        self.state = .playing
                    } else {
                        // НА FireTV когда заканчивается видео - оно висит на последней секунде, будто на паузе
                        //На Року оно закрывается. Поэтому надо обрабатывать все кейсы
                        if abs(TimeInterval(videoDuration) - currentTime) < 0.9 {
                            self.state = .stopped
                            timer.invalidate()
                        } else {
                            self.state = .paused
                        }
                    }
                } else if self.currentTime > 0 {
                    // Кейс когда предыдущий запрос был не 0, а следующий 0 это когда видео закончилось.
                    self.state = .stopped
                }
                self.currentTime = currentTime
                let currentTimePlayer = Int(currentTime)
                
                self.mediaControlView.progressView.value = Float(currentTimePlayer)/Float(videoDuration)
                self.mediaControlView.currentPlayTimeLabel.text = currentTimePlayer.durationText
            }
        })
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
            print(isSuggestionsOnView)
            print("textDidChange")
        }
    }
    
}

