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

enum State {
    case convertingToMP4(_ progress: Float)
}

class MediaPlayerViewController: BaseViewController {
    
    @IBOutlet weak var backInteractiveView: InteractiveView!
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    @IBOutlet weak var currentAssetNameLabel: DefaultLabel!
    @IBOutlet weak var hdCollectionView: CellConfiguratedCollectionView!
    @IBOutlet weak var thumbnailCollectionView: CellConfiguratedCollectionView!
    @IBOutlet weak var qualityInteractiveView: InteractiveView!
    @IBOutlet weak var qualityShadow: DropShadowView!
    
    private var videoPlayerManager = VideoPlayerManager.shared
    var hdCollectionViewRatio: CGFloat = 0
    var thumbnailCollectionViewThinnestRatio: CGFloat = 0
    var thumbnailCollectionViewThickestRatio: CGFloat = 0
    let thumbnailMaximumWidth:CGFloat = 160
    var flowLayoutSyncManager: FlowLayoutSyncManager!
    private let imageManager = PHCachingImageManager()
    var selectedIndex: Int = 0
    var assets: [PHAsset] = []
    var assetExportSession = VideoConverter()
    
    private var HUD: MBProgressHUD? {
        if _HUD == nil {
            let HUD = MBProgressHUD.showAdded(to: self.view, animated: true)
            HUD.mode = .determinate
            HUD.label.text = NSLocalizedString("Media.Player.Converting.Video", comment: "")
            HUD.button.setTitle(NSLocalizedString("Common.Cancel", comment: ""), for: .normal)
            HUD.progressObject = Progress(totalUnitCount: 100)
            _HUD = HUD
        }
        return _HUD
    }
   
    private var _HUD: MBProgressHUD?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let hdCellNib = UINib(nibName: HDCell.Identifier, bundle: .main)
        hdCollectionView.register(hdCellNib, forCellWithReuseIdentifier: HDCell.Identifier)
        
        let thumbnailCellNib = UINib(nibName: ThumbnailCell.Identifier, bundle: .main)
        thumbnailCollectionView.register(thumbnailCellNib, forCellWithReuseIdentifier: ThumbnailCell.Identifier)
        
        setupHDCollectionView()
        setupThumbnailCollectionView()//thumbnailCollectionView.dataSource = self
        
        
        flowLayoutSyncManager.register(hdCollectionView)
        flowLayoutSyncManager.register(thumbnailCollectionView)
        
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.navigation?.popViewController(self, animated: true)
        }
        
        connectInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.presentDevices(postAction: nil)
        }
        
        qualityInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.presentSettings(postAction: nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            self.hdCollectionView.scrollToItem(at: IndexPath(row: self.selectedIndex, section: 0), at:.centeredHorizontally, animated: false)
            self.thumbnailCollectionView.scrollToItem(at: IndexPath(row: self.selectedIndex, section: 0), at:.centeredHorizontally, animated: false)
            let asset = self.assets[self.selectedIndex]
            let resources = PHAssetResource.assetResources(for: asset)
            self.currentAssetNameLabel.text = resources.first?.originalFilename
        }
        
        qualityShadow.layer.cornerRadius = 15
        
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //        if let layout = thumbnailCollectionView.collectionViewLayout as? ThumbnailFlowLayoutDraggingBehavior {
        //            layout.unfoldCurrentCell()
        //        }
        
        if assets[selectedIndex].mediaType == .image {
            saveImageToDirectory(onComplete: castImageToTV)
        } else {
            saveVideoToDirectory(onComplete: castVideoToTV)
        }
    }
    
    private func showHUD() {
        HUD?.show(animated: true)
    }
    
    private func hideHUD() {
        _HUD?.hide(animated: true)
        _HUD = nil
    }
    
    private func stopObservePlayerState() {
        videoPlayerManager.stateObserver = nil
    }
    
    
    private func observeVideoPlayerState() {
        videoPlayerManager.stateObserver = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .convertingToMP4(let progress):
                self.HUD?.label.text = NSLocalizedString("Media.Player.Converting.Video", comment: "")
                self.HUD?.progressObject?.completedUnitCount = Int64(progress * 100)
                break
            }
        }
    }
    
    private func castVideoToTV() {
        stopObservePlayerState()
        hideHUD()
        let ipAddress = ServerConfiguration.shared.deviceIPAddress()
        guard let url = URL(string: "http://\(ipAddress):\(Port.app.rawValue)/video/\(UUID().uuidString)") else { return }
        ChromeCastService.shared.displayVideo(with: url)
    }
    
    private func castImageToTV() {
        let ipAddress = ServerConfiguration.shared.deviceIPAddress()
        guard let url = URL(string: "http://\(ipAddress):\(Port.app.rawValue)/image/\(UUID().uuidString)") else { return }
        ChromeCastService.shared.displayImage(with: url)
    }
    
    private func saveImageToDirectory(onComplete: Closure?) {
        guard presentedViewController == nil else { return }
        
        let currentAsset = assets[selectedIndex]
        image(for: currentAsset, size: PHImageManagerMaximumSize) { (image, need) in
            
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let imageFileURL = documentsDirectory.appendingPathComponent("imageForCasting.jpeg")
            guard let imageToCast = image else { return }
            guard let data = imageToCast.jpegData(compressionQuality: 0.9) else { return }
            
            if FileManager.default.fileExists(atPath: imageFileURL.path) {
                do {
                    try FileManager.default.removeItem(atPath: imageFileURL.path)
                    print("Removed old image")
                } catch let removeError {
                    print("couldn't remove file at path", removeError)
                }
            }
            
            do {
                try data.write(to: imageFileURL)
                print("IMAGE SIZE \(data.count)")
            } catch let error {
                print("error saving file with error", error)
            }
            
            onComplete?()
        }
    }
    
    private func saveVideoToDirectory(onComplete: Closure?) {
        
        observeVideoPlayerState()
        
        let currentAsset = assets[selectedIndex]
        
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.version = .original
        
        imageManager.requestAVAsset(forVideo: currentAsset, options: options) { [weak self] (avasset, audiomix, info) in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard let avasset = avasset else { return }
//                self.convertVideoToMP4(avasset, onComplete: onComplete)
                self.videoPlayerManager.convertVideoToMP4(avasset, onComplete: onComplete)
            }
        }
    }
    
//    private func convertVideoToMP4(_ avasset: AVAsset, onComplete: Closure?) {
//        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
//        let videoFileURL = documentsDirectory.appendingPathComponent("videoForCasting.mp4")
//        let quality = Settings.current.videosResolution
//
//        stateObserver?(.convertingToMP4(0))
//
//        if FileManager.default.fileExists(atPath: videoFileURL.path) {
//            do {
//                try FileManager.default.removeItem(atPath: videoFileURL.path)
//                print("Removed old video")
//            } catch let removeError{
//                print("couldn't remove file at path", removeError)
//            }
//        }
//
//        assetExportSession.exportAsset(asset: avasset, quality: quality, toFileURL: videoFileURL, onProgress: { [weak self] progress in
//            guard let self = self else { return }
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                self.stateObserver?(.convertingToMP4(progress))
//            }
//        }, onComplete: { [weak self] isSuccess in
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                if isSuccess {
//                    onComplete?()
//                    self.hideHUD()
//                } else {
//
//                }
//            }
//        })
//
//    }
    
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
    
    private func presentSettings(postAction: (() -> ())?) {
        let controller = MirrorSettingsViewController()
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
    
    override func viewDidLayoutSubviews() {
        setupHDCollectionViewMeasurement()
        hdCollectionView.collectionViewLayout.invalidateLayout()
        setupThumbnailCollectionViewMeasurement()
        thumbnailCollectionView.collectionViewLayout.invalidateLayout()
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
        thumbnailCollectionView.cellFullSpacing = 15
        thumbnailCollectionView.cellNormalSpacing = 2
        thumbnailCollectionView.cellHeight = thumbnailCollectionView.frame.size.height
        thumbnailCollectionView.cellMaximumWidth = thumbnailMaximumWidth
        thumbnailCollectionViewThinnestRatio = thumbnailCollectionView.cellHeight / thumbnailCollectionView.cellNormalWidth
        thumbnailCollectionViewThickestRatio = thumbnailCollectionView.cellHeight / thumbnailMaximumWidth
        if var layout = hdCollectionView.collectionViewLayout as? FlowLayoutInvalidateBehavior {
            layout.shouldLayoutEverything = true
        }
    }
}

//MARK: UICollectionViewDataSource

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
            //            if let image = hdPhotoModel.photo(at: indexPath.row),
            if let size = self.collectionView(hdCollectionView, sizeForItemAt: indexPath) {
                cell.photoWidthConstraint.constant = size.width
                cell.photoHeightConstraint.constant = size.height
                cell.clipsToBounds = true
                cell.photoImageView?.contentMode = .scaleAspectFit
                if asset.mediaType == .image {
                    cell.playerButtonsContainer.isHidden = true
                }
                //                cell.photoImageView?.image = image
                image(for: asset, size: CGSize(width: size.width, height: size.height)) { (image, needd) in
                    cell.photoImageView?.image = image
                }
            }
            return cell
        case thumbnailCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ThumbnailCell.Identifier, for: indexPath) as! ThumbnailCell
            let asset = assets[indexPath.row]
            //            if let image = thumbnailPhotoModel.photo(at: indexPath.row) {
            cell.photoHeightConstraint.constant = 49
            cell.photoWidthConstraint.constant = 23
            cell.clipsToBounds = true
            cell.photoImageView.contentMode = .scaleAspectFit
            //            asset.pixelWidth //temp as
            image(for: asset, size: CGSize(width: 23, height: 49)) { (image, needd) in
                cell.photoImageView.image = image
            }
            //                cell.photoImageView.image = image
            //            }
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
            if let layout = collectionView.collectionViewLayout as? ThumbnailFlowLayoutDraggingBehavior { //temp as
                layout.foldCurrentCell()
            }
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let collectionView = scrollView as? UICollectionView,
           let layout = collectionView.collectionViewLayout as? ThumbnailFlowLayoutDraggingBehavior{ //temp as
            layout.unfoldCurrentCell()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate,
           let collectionView = scrollView as? UICollectionView,
           let layout = collectionView.collectionViewLayout as? ThumbnailFlowLayoutDraggingBehavior{ //temp as
            layout.unfoldCurrentCell()
            print(self.selectedIndex)
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
            //            if let size = thumbnailPhotoModel.photoSize(at: indexPath.row) {
            //                return cellSize(forThumbImage: size)
            //            }
            return cellSize(forThumbImage: CGSize(width: 24, height: 49)) //CGSize(width: 24, height: 49)
        default:
            return nil
        }
        return nil
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case hdCollectionView:
            break
        case thumbnailCollectionView:
            hdCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            thumbnailCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        default:
            break
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
    
    /*
     image(for: asset, size: CGSize(width: 109, height: 109)) { (image, needd) in
     cell.previewImageView.image = image
     }
     
     private let imageManager = PHCachingImageManager()
     */
    
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
