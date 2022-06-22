//
//  MediaViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 21.04.2022.
//

import UIKit
import AudioToolbox
import Photos
import MBProgressHUD
import GoogleCast
import Agregator
import RealmSwift
import ZMJTipView

enum State {
    case convertingToMP4(_ progress: Float)
}

class MediaPlayerViewController: BaseViewController {
    
    deinit {
        print(">>> deinit MediaPlayerViewController")
        AgregatorLogger.shared.log(eventName: "Media player dealloc", parameters: nil)
    }
    
    @IBOutlet weak var backInteractiveView: InteractiveView!
    
    @IBOutlet weak var resumeVideoInteractiveView: ResumeVideoView!
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    
    @IBOutlet weak var navigationBarTitle: UILabel!
    @IBOutlet weak var currentAssetNameLabel: DefaultLabel!
    @IBOutlet weak var hdCollectionView: CellConfiguratedCollectionView!
    @IBOutlet weak var thumbnailCollectionView: CellConfiguratedCollectionView!
    @IBOutlet weak var qualityInteractiveView: InteractiveView!
    @IBOutlet weak var qualityTitleLabel: DefaultLabel!
    @IBOutlet weak var qualityShadow: DropShadowView!
   
    var navigationTitle: String?
    private var videoPlayerManager = VideoPlayerManager.shared
    var hdCollectionViewRatio: CGFloat = 0
    var thumbnailCollectionViewThinnestRatio: CGFloat = 0
    var thumbnailCollectionViewThickestRatio: CGFloat = 0
    let thumbnailMaximumWidth:CGFloat = 160
    var flowLayoutSyncManager: FlowLayoutSyncManager!
    private let imageManager = PHCachingImageManager()
    var selectedIndex: Int = 0
    var playingVideoIndex: Int = -1
    
    var assets: [PHAsset] = []
    var assetExportSession = VideoConverter()
    
    private var isTipWasShown = false
    private var tipView: ZMJTipView?
    
    private var delayBetweenCastTimer: Timer? //Чтобы не кастить фотки при каждом свайпе - делаю делей на 0.5 секунды
    
    private var iCloudRequestID: PHImageRequestID?
    
    private var HUD: MBProgressHUD? {
        if _HUD == nil {
            let HUD = MBProgressHUD.showAdded(to: self.view, animated: true)
            HUD.mode = .determinate
            HUD.label.text = NSLocalizedString("Media.Player.Load.iCloud", comment: "")
            HUD.button.setTitle(NSLocalizedString("Common.Cancel", comment: ""), for: .normal)
            HUD.progressObject = Progress(totalUnitCount: 100)
            _HUD = HUD
            print(">>>> HUD shown")
        }
        return _HUD
    }
    
    private var _HUD: MBProgressHUD?
    private var settingsObserver: NotificationToken!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AgregatorLogger.shared.log(eventName: "Media_player", parameters: nil)
        
        setupNavigationSection()
        registerUICollectionsCells()
        setupHDCollectionView()
        setupThumbnailCollectionView()
        synchronizeFlowLayoutOfCollections()
        observeSettings()
        
        hdCollectionView.alpha = 0
        thumbnailCollectionView.alpha = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
//            if self.selectedIndex > 0 {
                self.hdCollectionView.scrollToItem(at: IndexPath(row: self.selectedIndex, section: 0), at:.centeredHorizontally, animated: false)
                self.thumbnailCollectionView.scrollToItem(at: IndexPath(row: self.selectedIndex, section: 0), at:.centeredHorizontally, animated: false)
                UIView.animate(withDuration: 0.2 ) { [weak self] in
                    guard let self = self else { return }
                    self.hdCollectionView.alpha = 1
                    self.thumbnailCollectionView.alpha = 1
                }
//            }
            let asset = self.assets[self.selectedIndex]
            let resources = PHAssetResource.assetResources(for: asset)
            self.currentAssetNameLabel.text = resources.first?.originalFilename
            //self.handleAsset(at: self.selectedIndex)
        }
        
        showHideResumeButton()
        
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            stopDelayBetweenCastTimer()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        handleAsset(at: selectedIndex)
    }
    
    private func castToTV() {
        guard presentedViewController == nil else { return }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        stopObservePlayerState()
        videoPlayerManager.stop()
        
        let currentAsset = assets[selectedIndex]
        if currentAsset.mediaType == .image {
            prepareAsset(at: selectedIndex) { [weak self] image in
                guard let self = self else { return }
//                self.hdCollectionView.reloadData() 
                self.connectIfNeeded { [weak self] in
                    guard let self = self, let image = image else { return }
                    self.castPhotoToTV(image)
                }
            }
        } else if currentAsset.mediaType == .video {
            
            //temp as
            connectIfNeeded { [weak self] in
                guard let self = self else { return }
                self.castVideoToTV()
            }
            
        }
        
        print(">>> cast to TV, mediaType: \(currentAsset.mediaType)")
    }
    
    private func observeSettings() {
        settingsObserver = Settings.current.observe {  [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .error(_): break
            case .change(_, let properties):
                for property in properties {
                    if property.name == #keyPath(Settings.photosResolution){
                        self.handleAsset(at: self.selectedIndex)
                    }
                    
                    if property.name == #keyPath(Settings.videosResolution) {
                        UserDefaults.standard.lastCompressedAssetId = nil
                        self.handleAsset(at: self.selectedIndex)
                    }
                }
            case .deleted: break
            }
        }
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
    
    
    private func handleAsset(at index: Int) {
        AgregatorLogger.shared.log(eventName: "Media player handle asset", parameters: nil)
        
        guard index >= 0, index < assets.count else { return }
        let asset = assets[index]
        let resources = PHAssetResource.assetResources(for: asset)
        currentAssetNameLabel.text = resources.first?.originalFilename
        
        selectedIndex = index
        scrollTo(index: index, animated: true)
        setupQualityView(forMediaType: asset.mediaType)
        startDelayBetweenCastTimer()

    }
    
    private func scrollTo(index: Int, animated: Bool) {
        let indexPath = IndexPath(row: index, section: 0)
        hdCollectionView.scrollToItem(at: indexPath, at:.centeredHorizontally, animated: animated)
        thumbnailCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }
    
    private func setupQualityView(forMediaType type: PHAssetMediaType) {
        qualityTitleLabel.text = type == .image ? Settings.current.photosResolution.localizedValue : Settings.current.videosResolution.localizedValue
    }
    
    private func startDelayBetweenCastTimer() {
        stopDelayBetweenCastTimer()
        
        delayBetweenCastTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] (timer) in
            guard let self = self else { return }
            self.castToTV()
        })
    }
    
    private func stopDelayBetweenCastTimer() {
        delayBetweenCastTimer?.invalidate()
        delayBetweenCastTimer = nil
    }
    
    
    private func setupNavigationSection() {
        
        if let navTitle = self.navigationTitle {
            navigationBarTitle.text = navTitle
        }
       
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.tipView?.isHidden = true
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
        
        qualityInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.presentSettings(postAction: {
                self.updateUIbasedOnQuality()
            })
        }
    }
    
    private func updateUIbasedOnQuality(){
        let currentQuality = StreamConfiguration.current.resolutionType
        switch currentQuality {
        case .low:
            qualityTitleLabel.text = NSLocalizedString("Screen.Mirror.Quality.Optimized", comment: "")
        case .medium:
            qualityTitleLabel.text = NSLocalizedString("Screen.Mirror.Quality.Balanced", comment: "")
        case .high:
            qualityTitleLabel.text = NSLocalizedString("Screen.Mirror.Quality.Best", comment: "")
        default:
            break
        }
    }
    
    private func showHUD() {
        HUD?.show(animated: true)
    }
    
    private func hideHUD() {
        _HUD?.hide(animated: true)
//        HUD?.hide(animated: true)
        _HUD = nil
        
        print(">>>> HUD hide")
    }
    
    private func presentDevices(postAction: Closure?) {
        AgregatorLogger.shared.log(eventName: "Media player device list", parameters: nil)
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
    
    private func presentSettings(postAction: Closure?) {
        let asset = assets[selectedIndex]
        let controller = MediaSettingsViewController()
        controller.canDismissOnPan = true
        controller.isInteractiveBackground = false
        controller.grabberState = .inside
        controller.grabberColor = UIColor.black.withAlphaComponent(0.8)
        controller.modalPresentationStyle = .overCurrentContext
        if asset.mediaType == .image {
            controller.currentResolution = Settings.current.photosResolution
        } else if asset.mediaType == .video {
            controller.currentResolution = Settings.current.videosResolution
        }
        controller.didFinishAction = { [weak self] (resolution) in
            guard let self = self else { return }
            
            let params = [
                "previous value": Settings.current.videosResolution.eventTitle,
                "quality": resolution.eventTitle
            ]
            AgregatorLogger.shared.log(eventName: "Media quality changed", parameters: params)
            self.updateResolution(for: asset.mediaType, newResolution: resolution)
            
            postAction?()
        }
        present(controller, animated: false, completion: nil)
    }
    
    private func updateResolution(for mediaType: PHAssetMediaType, newResolution: ResolutionType) {
        Settings.current.realm?.beginWrite()
        if mediaType == .image {
            Settings.current.photosResolution = newResolution
        } else if mediaType == .video {
            Settings.current.videosResolution = newResolution
        }
        try? Settings.current.realm?.commitWrite()
    }
    
    private func connectIfNeeded(onComplete: Closure?) {
        AgregatorLogger.shared.log(eventName: "Media player reconnect", parameters: nil)
        guard GCKCastContext.sharedInstance().sessionManager.connectionState.rawValue != 2 else {
            onComplete?()
            return
        }
        presentDevices {
            onComplete?()
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
    
}


//MARK: - Photo
extension MediaPlayerViewController {
    
    private func prepareAsset(at index: Int, onComplete: ((UIImage?) -> ())?) {
        let asset = assets[index]
        iCloudRequestID = imageManager.image(
            for: asset,
            size: PHImageManagerMaximumSize,
            contentMode: .aspectFill,
            progressHandler: { [weak self] progress in
                guard let self = self else { return }
                print(">>>> photos from iCLoud progress: \(progress)")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if progress == 100 {
                        self.hideHUD()
                    } else {
                        self.HUD?.button.addTarget(self, action: #selector(self.cancelDownloadFromICloud(_:)), for: .touchUpInside)
                        self._HUD?.progressObject?.completedUnitCount = progress
                    }
                }
            }, completion: { [weak self] image in
                guard let self = self, let image = image else { return }
                print(">>>> photos from iCLoud ready")
                self.hideHUD()
                self.reloadCurrentHDCell()
                onComplete?(image)
            })
    }
    
    private func reloadCurrentHDCell() {
        let indexPath = IndexPath(row: selectedIndex, section: 0)
        guard let cell = hdCollectionView.cellForItem(at: indexPath) as? HDCell,
              let size = collectionView(hdCollectionView, sizeForItemAt: indexPath),
                selectedIndex < assets.count
        else { return }
        
        let asset = assets[selectedIndex]
        cell.setupCell(with: asset, state: videoPlayerManager.state, size: size, isVideoOfCellPlaying: selectedIndex == playingVideoIndex )
    }
    
    @objc fileprivate func cancelDownloadFromICloud(_ sender: Any) {
        if let iCloudRequestID = iCloudRequestID {
            imageManager.cancelImageRequest(iCloudRequestID)
        }
        hideHUD()
        
    }
    
    private func castPhotoToTV(_ image: UIImage) {
        guard presentedViewController == nil else { return }
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let imageFileURL = documentsDirectory.appendingPathComponent("imageForCasting.jpg")
        let compression = Settings.current.photosResolution.localImageCompression
        guard let data = image.jpegData(compressionQuality: compression) else { return }
        
        if FileManager.default.fileExists(atPath: imageFileURL.path) {
            try? FileManager.default.removeItem(atPath: imageFileURL.path)
            print("Removed old image")
        }
        try? data.write(to: imageFileURL)
        
        let ipAddress = ServerConfiguration.shared.deviceIPAddress()
        guard let url = URL(string: "http://\(ipAddress):\(Port.app.rawValue)/image/\(UUID().uuidString)") else { return }
        ChromeCastService.shared.displayImage(with: url)
        print(">>>File url \(url)")
    }
}

//MARK: - Video
extension MediaPlayerViewController {
    
    private func castVideoToTV() {
        
        playingVideoIndex = selectedIndex
        observeVideoPlayerState()
        
        let asset = assets[selectedIndex]
        if videoPlayerManager.asset != asset {
            videoPlayerManager.stop()
        }
        
        let state = videoPlayerManager.state
        switch state {
        case .none:
            //Запускаем процесс подготовки файла. Затем начинают последовательно отрабатывать state в функции observeVideoPlayerState
            videoPlayerManager.prepareAssetForCastToTV(asset)
        case .readyForTV:
            connectIfNeeded { [weak self] in
                guard let self = self else { return }
                let ipAddress = ServerConfiguration.shared.deviceIPAddress()
                guard let url = URL(string: "http://\(ipAddress):\(Port.app.rawValue)/video/\(UUID().uuidString)") else { return }
                if self.isTipWasShown == false {
                    self.resumeVideoInteractiveView.isHidden = false
                    self.showTipView()
                    self.isTipWasShown = true
                }
                ChromeCastService.shared.displayVideo(with: url)
                ChromeCastService.shared.showDefaultMediaVC()
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    //temp as
                    self.videoPlayerManager.startObserveVideoState()
                }
            }
        case .playing:
            //Если текущее состояние playing - значит надо поставить на паузу
            ChromeCastService.shared.pauseVideo()
            print(">>>VideoPlayer state .playing")
        case .paused:
            //Если текущее состояние paused - значит надо восстановить воспроизведение
            ChromeCastService.shared.playVideo()
            ChromeCastService.shared.showDefaultMediaVC()
            print(">>>VideoPlayer state .paused")
        default:
            break
        }
    }
    
    private func mediaCellPlayClicked() {
        stopDelayBetweenCastTimer() // кейс когда свайпнул вправо и сразу нажал на play. Начинается двойной preparing. Поэтому вырубаем таймер если на ячейке нажали play.
        castVideoToTV()
    }
    
    private func mediaCellPrevClicked() {
        handleAsset(at: selectedIndex - 1)
    }
    
    private func mediaCellNextClicked() {
        handleAsset(at: selectedIndex + 1)
    }
    
    private func mediaCellRewindClicked(seconds: TimeInterval){
        let options = GCKMediaSeekOptions()
        options.interval = seconds
        let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
        remoteMediaClient?.seek(with: options)
    }
    
    private func observeVideoPlayerState() {
        videoPlayerManager.stateObserver = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .none, .cancelled:
                print(">>>> state none")
                self.hideHUD()
                self.tipView?.isHidden = true
                self.reloadCurrentHDCell() 
            case .iCloudDownloading(let progress):
                print(">>>> state icloud: \(progress)")
                self.HUD?.button.addTarget(self, action: #selector(self.cancelPrepareVideo(_:)), for: .touchUpInside)
                self._HUD?.progressObject?.completedUnitCount = Int64(progress * 100)
            case .convertingToMP4(let progress):
                print(">>>> state convert: \(progress)")
                self.HUD?.label.text = NSLocalizedString("Media.Player.Converting.Video", comment: "")
                self.HUD?.progressObject?.completedUnitCount = Int64(progress * 100)
                break
            case .readyForTV:
                print(">>>> state ready to TV")
                self.hideHUD()
                self.reloadCurrentHDCell()
                self.castVideoToTV()
            case .playing:
                print(">>>> state playing")
                DispatchQueue.main.async { [weak self] in
                    self?.hdCollectionView.reloadData()
                }
            case .paused:
                print(">>>> state paused")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.hdCollectionView.reloadData()
                }
            }
        }
        videoPlayerManager.imageManager = imageManager
    }
    
    private func stopObservePlayerState() {
        videoPlayerManager.stateObserver = nil
    }
    
    @objc fileprivate func cancelPrepareVideo(_ sender: Any) {
        videoPlayerManager.cancelPreparing()
    }
}

//MARK: - UICollectionViewLayout
extension MediaPlayerViewController {
    override func viewDidLayoutSubviews() {
        setupHDCollectionViewMeasurement()
        hdCollectionView.collectionViewLayout.invalidateLayout()
        setupThumbnailCollectionViewMeasurement()
        thumbnailCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func registerUICollectionsCells() {
        let hdCellNib = UINib(nibName: HDCell.Identifier, bundle: .main)
        hdCollectionView.register(hdCellNib, forCellWithReuseIdentifier: HDCell.Identifier)
        
        let thumbnailCellNib = UINib(nibName: ThumbnailCell.Identifier, bundle: .main)
        thumbnailCollectionView.register(thumbnailCellNib, forCellWithReuseIdentifier: ThumbnailCell.Identifier)
    }
    
    fileprivate func setupHDCollectionView() {
        hdCollectionView!.cellSize = self
        hdCollectionView.dataSource = self
        hdCollectionView.delegate = self
        hdCollectionView!.isPagingEnabled = true
        hdCollectionView!.decelerationRate = UIScrollView.DecelerationRate.normal;
        let layout = HDFlowLayout()
        layout.flowLayoutSyncManager = flowLayoutSyncManager
        hdCollectionView!.collectionViewLayout = layout
    }
    
    fileprivate func setupThumbnailCollectionView() {
        thumbnailCollectionView!.dataSource = self
        thumbnailCollectionView!.delegate = self
        thumbnailCollectionView!.cellSize = self
        thumbnailCollectionView!.alwaysBounceHorizontal = true
        thumbnailCollectionView!.collectionViewLayout = ThumbnailSlaveFlowLayout()
    }
    
    fileprivate func setupHDCollectionViewMeasurement() {
        hdCollectionView.cellFullSpacing = 100
        hdCollectionView.cellNormalWidth = hdCollectionView!.bounds.size.width - hdCollectionView.cellFullSpacing
        hdCollectionView.cellMaximumWidth = hdCollectionView!.bounds.size.width
        hdCollectionView.cellNormalSpacing = 0
        hdCollectionView.cellHeight = hdCollectionView.bounds.size.height
        hdCollectionViewRatio = hdCollectionView.frame.size.height / hdCollectionView.frame.size.width
        if var layout = hdCollectionView.collectionViewLayout as? FlowLayoutInvalidateBehavior {
            layout.shouldLayoutEverything = true
        }
    }
    
    fileprivate func setupThumbnailCollectionViewMeasurement() {
        thumbnailCollectionView.cellNormalWidth = 30
        thumbnailCollectionView.cellFullSpacing = 8
        thumbnailCollectionView.cellNormalSpacing = 1
        thumbnailCollectionView.cellHeight = thumbnailCollectionView.frame.size.height
        thumbnailCollectionView.cellMaximumWidth = thumbnailMaximumWidth
        thumbnailCollectionViewThinnestRatio = thumbnailCollectionView.cellHeight / thumbnailCollectionView.cellNormalWidth
        thumbnailCollectionViewThickestRatio = thumbnailCollectionView.cellHeight / thumbnailMaximumWidth
        if var layout = hdCollectionView.collectionViewLayout as? FlowLayoutInvalidateBehavior {
            layout.shouldLayoutEverything = true
        }
    }
    
    private func synchronizeFlowLayoutOfCollections() {
        flowLayoutSyncManager.register(hdCollectionView)
        flowLayoutSyncManager.register(thumbnailCollectionView)
    }
}

//MARK: - UICollectionViewDataSource
extension MediaPlayerViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case hdCollectionView:
            return  assets.count //hdPhotoModel.numberOfPhotos()
        case thumbnailCollectionView:
            return  assets.count //thumbnailPhotoModel.numberOfPhotos()
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case hdCollectionView:
            let asset = assets[indexPath.row]
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HDCell.Identifier, for: indexPath) as! HDCell
            
            if let size = self.collectionView(hdCollectionView, sizeForItemAt: indexPath) {
                cell.setupCell(with: asset, state: videoPlayerManager.state, size: size, isVideoOfCellPlaying: selectedIndex == playingVideoIndex )
                cell.prevAction = mediaCellPrevClicked
                cell.nextAction = mediaCellNextClicked
                cell.playOrPauseAction = mediaCellPlayClicked
//                cell.rewindAction = mediaCellRewindClicked(seconds:)
            }
            
            return cell
        case thumbnailCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ThumbnailCell.Identifier, for: indexPath) as! ThumbnailCell
            let asset = assets[indexPath.row]
            cell.photoHeightConstraint.constant = 49
            cell.photoWidthConstraint.constant = 23
            cell.clipsToBounds = true
            cell.photoImageView.contentMode = .scaleAspectFill
            image(for: asset, size: CGSize(width: 23, height: 49)) { (image, needd) in
                cell.photoImageView.image = image
            }
            
            return cell
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case hdCollectionView:
            break
        case thumbnailCollectionView:
            hdCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            thumbnailCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            self.selectedIndex = indexPath.row
            let asset = self.assets[self.selectedIndex]
            let resources = PHAssetResource.assetResources(for: asset)
            self.currentAssetNameLabel.text = resources.first?.originalFilename
            self.handleAsset(at: selectedIndex)
            
        default:
            break
        }
    }
}

//MARK: - CollectionView Delegate
extension MediaPlayerViewController: UICollectionViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let collectionView = scrollView as? UICollectionView {
            flowLayoutSyncManager.masterCollectionView = collectionView
            if let layout = collectionView.collectionViewLayout as? ThumbnailFlowLayoutDraggingBehavior {
                layout.foldCurrentCell()
            }
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let collectionView = scrollView as? UICollectionView,
           let layout = collectionView.collectionViewLayout as? ThumbnailFlowLayoutDraggingBehavior {
            layout.unfoldCurrentCell()
            
            let center = self.view.convert(collectionView.center, to: collectionView)
            let index =  collectionView.indexPathForItem(at: CGPoint(x: center.x, y: 0))
            guard let thumbPage = index?.row else { return }
            if thumbPage != selectedIndex {
                selectedIndex = thumbPage
                let asset = self.assets[self.selectedIndex]
                let resources = PHAssetResource.assetResources(for: asset)
                self.currentAssetNameLabel.text = resources.first?.originalFilename
                self.handleAsset(at: selectedIndex)
            }
            
        } else {
            let page = Int(scrollView.contentOffset.x / scrollView.frame.width)
            if page != selectedIndex {
                selectedIndex = page
                let asset = self.assets[self.selectedIndex]
                let resources = PHAssetResource.assetResources(for: asset)
                self.currentAssetNameLabel.text = resources.first?.originalFilename
                self.handleAsset(at: selectedIndex)
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate,
           let collectionView = scrollView as? UICollectionView,
           let layout = collectionView.collectionViewLayout as? ThumbnailFlowLayoutDraggingBehavior{
            layout.unfoldCurrentCell()
            
            let center = self.view.convert(collectionView.center, to: collectionView)
            let index =  collectionView.indexPathForItem(at: CGPoint(x: center.x, y: 0))
            guard let thumbPage = index?.row else { return }
            if thumbPage != selectedIndex {
                selectedIndex = thumbPage
                self.handleAsset(at: selectedIndex)
            }
        }
        
    }
}

//MARK: - CollectionViewCellSize Protocol
extension MediaPlayerViewController: CollectionViewCellSize {
    func collectionView(_ collectionView: UICollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize? {
        switch collectionView {
        case hdCollectionView:
            //            if let size = hdPhotoModel.photoSize(at: indexPath.row) {
            //                return cellSize(forHDImage: size)
            //            }
            return CGSize(width: UIScreen.main.bounds.size.width, height: hdCollectionView.frame.height)
        case thumbnailCollectionView:
//                        if let size = thumbnailPhotoModel.photoSize(at: indexPath.row) {
//                            return cellSize(forThumbImage: size)
//                        }
            return cellSize(forThumbImage: CGSize(width: 24, height: 49)) //CGSize(width: 24, height: 49)
        default:
            return nil
        }
    }
    
    fileprivate func cellSize(forHDImage size: CGSize) -> CGSize? {
        let ratio = size.height / size.width
        if (ratio < hdCollectionViewRatio) {
            return CGSize(width: hdCollectionView.frame.size.width, height: hdCollectionView.frame.size.width * ratio)
        } else {
            return CGSize(width: hdCollectionView.frame.size.height / ratio, height: hdCollectionView.frame.size.height)
        }
    }
    
    fileprivate func cellSize(forThumbImage size: CGSize) -> CGSize? {
        let ratio = size.height / size.width
        if (ratio > thumbnailCollectionViewThinnestRatio) {
            return CGSize(width: thumbnailCollectionView.cellNormalWidth, height: thumbnailCollectionView.cellHeight)
        } else if ratio < thumbnailCollectionViewThickestRatio {
            return CGSize(width: thumbnailCollectionView.cellMaximumWidth, height: thumbnailCollectionView.cellHeight)
        } else {
            return CGSize(width: thumbnailCollectionView.frame.size.height / ratio, height: thumbnailCollectionView.frame.size.height)
        }
    }
}

extension MediaPlayerViewController {
    
    @discardableResult func image(for asset: PHAsset, size: CGSize, completion: @escaping ((UIImage?, Bool) -> Void)) -> PHImageRequestID {
        return imageManager.requestImage(
            for: asset,
               targetSize: size, //PHImageManagerMaximumSize
               contentMode: .aspectFill,
               options: nil,
               resultHandler: { (image, info) in
                   let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                   if isDegraded {
                       return
                   }
                   DispatchQueue.main.async {
                       completion(image, isDegraded)
                   }
               })
    }
}

extension PHCachingImageManager {
    @discardableResult
    func image(for asset: PHAsset,
               size: CGSize,
               contentMode: PHImageContentMode,
               devliveryMode: PHImageRequestOptionsDeliveryMode = .highQualityFormat,
               resizeMode: PHImageRequestOptionsResizeMode = .none,
               isNetworkAccessAllowed: Bool = true,
               progressHandler: ((Int64) -> ())? = nil,
               completion: @escaping ((UIImage?) -> Void)) -> PHImageRequestID {

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = isNetworkAccessAllowed
        options.deliveryMode = devliveryMode
        options.resizeMode = resizeMode
        options.version = .original
        options.progressHandler = { [weak self] (progress, error, data, info) in
            guard let _ = self else { return }
            progressHandler?(Int64(progress * 100))
        }
        
        return requestImage(
            for: asset,
               targetSize: size,
               contentMode: contentMode,
               options: options,
               resultHandler: { [weak self] (image, info) in
                   guard let _ = self else { return }
                   let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                   if isDegraded {
                       print(">>>> state isDegraded!!")
                       return
                   }
                   let result = image?.fixedOrientation()
                   DispatchQueue.main.async {
                       completion(result)
                   }
               })
    }
    
    func checkICloudStatus(for asset: PHAsset, completion: @escaping ((_ isPhotoInICloud: Bool) -> Void)) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .highQualityFormat
        options.version = .original
        options.resizeMode = .none
        requestImageDataAndOrientation(for: asset, options: options) { imageData, _, _, _ in
            DispatchQueue.main.async {
                completion(imageData == nil)
            }
        }
        
        //        let options = PHImageRequestOptions()
        //        options.isNetworkAccessAllowed = false
        //        options.deliveryMode = .highQualityFormat
        //        options.version = .original
        //        options.resizeMode = .none
        ////        requestImage(
        ////            for: asset,
        ////            targetSize: PHImageManagerMaximumSize,
        ////            contentMode: .aspectFit,
        ////            options: options,
        ////            resultHandler: { [weak self] (image, info) in
        //                guard let _ = self else { return }
        //                let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
        //                if isDegraded { return }
        //                DispatchQueue.main.async {
        //                    print(">>>> icloud!! \(info?[PHImageResultIsInCloudKey] != nil)")
        //                    completion(info?[PHImageResultIsInCloudKey] != nil)
        //                }
        //            })
    }
}
