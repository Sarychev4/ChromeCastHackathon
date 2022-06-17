//
//  MediaLibraryViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 28.04.2022.
//

import UIKit
import DeviceKit
import Photos
import GoogleCast
import Agregator

class MediaLibraryViewController: BaseViewController {
    
    @IBOutlet weak var backInteractiveView: InteractiveView!
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    @IBOutlet weak var separatorShadowView: DropShadowView!
    @IBOutlet weak var albumsScrollView: UIScrollView!
    @IBOutlet weak var albumsStackView: UIStackView!
    @IBOutlet weak var assetsCollectionView: UICollectionView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var albumViewsArray: [AlbumView] = []
    private var dataSource: [(album: PHAssetCollection, images:[PHAsset])] = []
    private var albumIndex: Int = 0 {
        didSet {
            updateUI()
        }
    }
    private let imageManager = PHCachingImageManager()
    private var shadowAnimator: UIViewPropertyAnimator?
    
    private let сellWidth = (UIScreen.main.bounds.width - 48 * SizeFactor) / 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AgregatorLogger.shared.log(eventName: "Media_library", parameters: nil)
        
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            ChromeCastService.shared.stopWebApp()
            self.navigation?.popViewController(self, animated: true)
        }
        
        connectInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.presentDevices(postAction: nil)
        }
        
        let assetCellNib = UINib(nibName: AssetCell.Identifier, bundle: .main)
        assetsCollectionView.register(assetCellNib, forCellWithReuseIdentifier: AssetCell.Identifier)
        
        albumsScrollView.contentInset = UIEdgeInsets(top: 0, left: 16 * SizeFactor, bottom: 0, right: 16 * SizeFactor)
        assetsCollectionView.contentInset = UIEdgeInsets(top: 16, left: 16 * SizeFactor, bottom: 0, right: 16 * SizeFactor)
        
        assetsCollectionView.dataSource = self
        assetsCollectionView.delegate = self
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            self.requestAccessPermition()
        }
        
        setupShadowAnimation()
        activityIndicator.startAnimating()
        
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            shadowAnimator?.stopAnimation(true)
            if shadowAnimator?.state != .inactive {
                shadowAnimator?.finishAnimation(at: .current)
            }
        }
    }
    
    // Request permission to access photo library
    private func requestAccessPermition() {
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.setupAlbums()
            }
        } else {
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] (status) in
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        if status == .authorized || status == .limited {
                            self.setupAlbums()
                        } else {
                            self.showAlertAccessRequired { [weak self] in
                                guard let _ = self else { return }
                                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                                
                                if UIApplication.shared.canOpenURL(settingsURL) {
                                    UIApplication.shared.open(settingsURL, completionHandler: { (success) in
                                        
                                    })
                                }
                            }
                        }
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization{ [weak self] (status) in
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        if status == .authorized {
                            self.setupAlbums()
                        } else {
                            self.showAlertAccessRequired { [weak self] in
                                guard let _ = self else { return }
                                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                                
                                if UIApplication.shared.canOpenURL(settingsURL) {
                                    UIApplication.shared.open(settingsURL, completionHandler: { (success) in
                                        
                                    })
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func setupAlbums() {
        
        AgregatorLogger.shared.log(eventName: "Media_setup_albums", parameters: nil)
        
        albumViewsArray.forEach({ $0.removeFromSuperview(); albumsStackView.removeArrangedSubview($0) })
        albumViewsArray.removeAll()
        dataSource.removeAll()
        
        let fetchOptions = PHFetchOptions() //A set of options that affect the filtering, sorting, and management of results that Photos returns when you fetch asset or collection objects.
        let smartAlbumEntry = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: fetchOptions)//A PHAssetCollection object represents a collection of photo or video assets, such as an album, moment, or Shared Photo Stream.
        smartAlbumEntry.enumerateObjects { (collection, index, stop) in
            let assets = self.fetchAssets(in: collection)
            if assets.count > 0 {
                self.dataSource.append((collection, assets))
            }
        }
        
        let userCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        userCollections.enumerateObjects { (collection, index, stop) in
            let assets = self.fetchAssets(in: collection)
            if assets.count > 0 {
                self.dataSource.append((collection, assets))
            }
        }
        
        let albums = dataSource.map({$0.album})
        for (index, album) in albums.enumerated() {
            let view = AlbumView()
            view.titleLabel.text = album.localizedTitle
            view.containerInteractiveView.didTouchAction = { [weak self] in
                guard let self = self else { return }
                let numberOfPhotosInAlbum = self.dataSource[self.albumIndex].images.count
                if numberOfPhotosInAlbum > 0 {
                    self.assetsCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: [], animated: false)
                }
                self.albumIndex = index
            }
            self.albumsStackView.addArrangedSubview(view)
            self.albumViewsArray.append(view)
        }
        updateUI()
    }
    
    private func updateUI() {
        for (index, view) in albumViewsArray.enumerated() {
            view.isSelected = index == albumIndex
        }
        
        assetsCollectionView.reloadData()
        activityIndicator.stopAnimating()
    }
    
    func fetchAssets(in album: PHAssetCollection) -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format:"mediaType = %d || mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        
        let fetchResult = PHAsset.fetchAssets(in: album, options: options)
        let indexSet = IndexSet(0..<fetchResult.count)
        return fetchResult.objects(at: indexSet)
    }
    
    private func showAlertAccessRequired(onComplete: (() -> ())?) {
        let alertView = AlertViewController(
            alertTitle: NSLocalizedString("Alert.Permissions.Denied.Library.Title", comment: ""),
            alertSubtitle: NSLocalizedString("Alert.Permissions.Denied.Library.Message", comment: ""),
            continueAction: NSLocalizedString("Alert.Permissions.Denied.Library.Continue", comment: ""),
            leftAction: nil,
            rightAction: nil
        )
        
        alertView.continueClicked = {
            onComplete?()
            alertView.dismiss()
        }
        alertView.present(from: self)
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

extension MediaLibraryViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let albumsCount = dataSource.map({ $0.album }).count
        guard albumsCount > 0 else {
            return 0
        }
        let numberOfPhotosInCategory = dataSource[albumIndex].images.count
        return numberOfPhotosInCategory
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetCell.Identifier, for: indexPath) as! AssetCell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? AssetCell {
            let asset = dataSource[albumIndex].images[indexPath.row] //A representation of an image, video, or Live Photo in the Photos library.
            cell.type = asset.mediaType
            image(for: asset, size: CGSize(width: 109, height: 109)) { (image, needd) in
                cell.previewImageView.image = image
            }
            if cell.type == .video {
                cell.itemDurationLabel.text = asset.duration.durationText
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: сellWidth, height: сellWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8 * SizeFactor
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8 * SizeFactor
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let player = MediaPlayerViewController()
        let item = dataSource[albumIndex]
        player.navigationTitle = item.album.localizedTitle
        player.selectedIndex = indexPath.row
        player.flowLayoutSyncManager = FlowLayoutSyncManager()
        player.assets = dataSource[albumIndex].images
        navigation?.pushViewController(player, animated: .left)
    }
}

//MARK: - Extension ScrollView
extension MediaLibraryViewController: UIScrollViewDelegate {
    
    private func setupShadowAnimation() {
        separatorShadowView.alpha = 0
        shadowAnimator = UIViewPropertyAnimator(duration: 0.1, curve: .easeOut, animations: { [weak self] in
            guard let self = self else { return }
            self.separatorShadowView.alpha = 1.0
        })
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPosition = Int(scrollView.contentOffset.y + scrollView.contentInset.top)
        let minValue = -1
        let maxValue = 16
        let distance = maxValue - minValue
        
        if currentPosition < maxValue, currentPosition > minValue {
            let progress = abs(CGFloat(currentPosition) / CGFloat(distance))
            updateShadow(with: progress)
        } else if currentPosition > maxValue {
            if shadowAnimator?.fractionComplete != 1 {
                updateShadow(with: 1)
            }
        } else if currentPosition < minValue {
            if shadowAnimator?.fractionComplete != 0 {
                updateShadow(with: 0)
            }
        }
    }
    
    private func updateShadow(with progress: CGFloat) {
        shadowAnimator?.fractionComplete = progress
    }
}

extension MediaLibraryViewController {
    
    /*
     image(for: asset, size: CGSize(width: 109, height: 109)) { (image, needd) in
         cell.previewImageView.image = image
     }
     
     private let imageManager = PHCachingImageManager()
     */
    
    @discardableResult func image(for asset: PHAsset, size: CGSize, completion: @escaping ((UIImage?, Bool) -> Void)) -> PHImageRequestID {
        return imageManager.requestImage(
            for: asset,
            targetSize: size,
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

extension Double {
    var durationText:String {
        if self.isNaN {
            return "00:00"
        }
        let totalSeconds = self
        let hours:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 86400) / 3600)
        let minutes:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds:Int = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
        
    }
}

extension Int {
    var durationText:String {
        return Double(self).durationText
    }
}
