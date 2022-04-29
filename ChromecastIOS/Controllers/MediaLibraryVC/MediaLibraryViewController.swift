//
//  MediaLibraryViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 28.04.2022.
//

import UIKit
import DeviceKit
import Photos

class MediaLibraryViewController: BaseViewController {
    
    
    @IBOutlet weak var backInteractiveView: InteractiveView!
    
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    
    @IBOutlet weak var topContainerView: UIView!
    @IBOutlet weak var topDropShadowView: DropShadowView!
    @IBOutlet weak var topCategoriesScrollView: UIScrollView!
    @IBOutlet weak var topCategoriesStackView: UIStackView!
    
    @IBOutlet weak var mediaItemsCollectionView: UICollectionView!
    
    private var shadowAnimator: UIViewPropertyAnimator?
    private var categoryItemsViews: [CategoryItemView] = []
    private let imageManager = PHCachingImageManager()
    private var datasource: [(album: PHAssetCollection, images:[PHAsset])] = []
    private var categoryIndex: Int = 0 {
        didSet {
            updateUI()
        }
    }
    
    let CellWidth = (UIScreen.main.bounds.width - 48 * SizeFactor) / 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.navigation?.popViewController(self, animated: true)
        }
        
        connectInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.presentDevices(postAction: nil)
        }
        
        let collectionItemCellNib = UINib(nibName: MediaItemCollectionViewCell.Identifier, bundle: .main)
        mediaItemsCollectionView.register(collectionItemCellNib, forCellWithReuseIdentifier: MediaItemCollectionViewCell.Identifier)
        
        topCategoriesScrollView.contentInset = UIEdgeInsets(top: 0, left: 16 * SizeFactor, bottom: 0, right: 16 * SizeFactor)
        mediaItemsCollectionView.contentInset = UIEdgeInsets(top: 16, left: 16 * SizeFactor, bottom: 0, right: 16 * SizeFactor)
        
        
        mediaItemsCollectionView.dataSource = self
        mediaItemsCollectionView.delegate = self
        
        requestPermissions()
        setupShadowAnimation()
    }
    
    
    /*
     MARK: - Methods
     */
    
    private func requestPermissions() {
        
        func finish() {
            setupCategories()
        }
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            finish()
        } else {
            PHPhotoLibrary.requestAuthorization { [weak self] (status) in
                DispatchQueue.main.async { [weak self] in
                    if status == .authorized {
                        finish()
                    } else {
                        self?.showAlertAccessRequired { [weak self] in
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
    
    private func setupCategories() {
        categoryItemsViews.forEach({ $0.removeFromSuperview(); topCategoriesStackView.removeArrangedSubview($0) })
        categoryItemsViews.removeAll()
        datasource.removeAll()
        
        let fetchOptions = PHFetchOptions()
        
        let smartAlbumEntry = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: fetchOptions)
        smartAlbumEntry.enumerateObjects { (collection, index, stop) in
            let assets = self.fetchAssets(in: collection)
            if assets.count > 0 {
                self.datasource.append((collection, assets))
            }
        }
        
        let userCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        userCollections.enumerateObjects { (collection, index, stop) in
            let assets = self.fetchAssets(in: collection)
            if assets.count > 0 {
                self.datasource.append((collection, assets))
            }
        }
        
        for (index, album) in datasource.map({ $0.album }).enumerated() {
            let view = CategoryItemView()
            view.titleLabel.text = album.localizedTitle
            view.containerInteractiveView.didTouchAction = { [weak self] in
                guard let self = self else { return }
                let numberOfPhotosInAlbum = self.datasource[self.categoryIndex].images.count
                if numberOfPhotosInAlbum > 0 {
                    self.mediaItemsCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: [], animated: false)
                }
                
                self.categoryIndex = index
            }
            self.topCategoriesStackView.addArrangedSubview(view)
            self.categoryItemsViews.append(view)
        }
        
        self.updateUI()
    }
    
    private func updateUI() {
        for (index, view) in categoryItemsViews.enumerated() {
            view.isSelected = index == categoryIndex
        }
        mediaItemsCollectionView.reloadData()
    }
    
    private func showAlertAccessRequired(onComplete: (() -> ())?) {
        
        let alertView = AlertViewController(
            alertTitle: NSLocalizedString("Alert.Permissions.Denied.LocalNetwork.Title", comment: ""),
            alertSubtitle: NSLocalizedString("Alert.Permissions.Denied.LocalNetwork.Subtitle", comment: ""),
            continueAction: NSLocalizedString("Alert.Permissions.Denied.LocalNetwork.Continue", comment: "")
        )
        
        alertView.continueClicked = {
            onComplete?()
            alertView.dismiss()
        }
        
        alertView.present(from: self)
    }
    
    private func presentDevices(postAction: (() -> ())?) {
        let controller = ListDevicesViewController()
        controller.canDismissOnPan = false
        controller.isInteractiveBackground = false
        controller.grabberState = .inside
        controller.grabberColor = UIColor.black.withAlphaComponent(0.8)
        controller.modalPresentationStyle = .overCurrentContext
        controller.didFinishAction = {  [weak self] in
            guard let self = self else { return }
            postAction?()
        }
        present(controller, animated: false, completion: nil)
    }
}





//MARK: - Extension CollectionView
extension MediaLibraryViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let categoryCount = datasource.map({ $0.album }).count
        guard categoryCount > 0 else {
            return 0
        }
        let numberOfPhotosInCategory = datasource[categoryIndex].images.count
        return numberOfPhotosInCategory
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaItemCollectionViewCell.Identifier, for: indexPath) as! MediaItemCollectionViewCell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? MediaItemCollectionViewCell {
            let asset = datasource[categoryIndex].images[indexPath.row]
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
        return CGSize(width: CellWidth, height: CellWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8 * SizeFactor
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8 * SizeFactor
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let player = MediaPlayerViewController()
//        player.selectedIndex = indexPath.row
//        player.assets = datasource[albumIndex].images
//        navigation?.pushViewController(player, animated: .left)
    }
}

//MARK: - Extension ScrollView
extension MediaLibraryViewController: UIScrollViewDelegate {
    
    private func setupShadowAnimation() {
        topDropShadowView.alpha = 0
        shadowAnimator = UIViewPropertyAnimator(duration: 0.1, curve: .easeOut, animations: { [weak self] in
            guard let self = self else { return }
            self.topDropShadowView.alpha = 1.0
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
    
    func fetchAssets(in album: PHAssetCollection) -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format:"mediaType = %d || mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        
        let fetchResult = PHAsset.fetchAssets(in: album, options: options)
        let indexSet = IndexSet(0..<fetchResult.count)
        return fetchResult.objects(at: indexSet)
    }
    
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
