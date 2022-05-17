//
//  MediaViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 21.04.2022.
//

import UIKit
import AudioToolbox
import Photos

class MediaPlayerViewController: BaseViewController {
    
    @IBOutlet weak var backInteractiveView: InteractiveView!
    @IBOutlet weak var currentAssetNameLabel: DefaultLabel!
    @IBOutlet weak var hdCollectionView: CellConfiguratedCollectionView!
    @IBOutlet weak var thumbnailCollectionView: CellConfiguratedCollectionView!
    @IBOutlet weak var qualityInteractiveView: InteractiveView!
    @IBOutlet weak var qualityShadow: DropShadowView!
    
    //    private var hdPhotoModel: PhotoModel = PhotoCollection(photos: ["barton_nature_leeve_hd.JPG", "barton_nature_area_bridge_hd.JPG", "barton_nature_lake_hd.JPG", "barton_nature_swan_hd.JPG", "bird_hills_nature_tree_hd.JPG", "bird_hills_nature_sunset_hd.JPG", "huron_river_hd.JPG", "bird_hills_nature_foliage_hd.JPG","leslie_park_hd.png", "willowtree_apartment_sunset_hd.jpg", "vertical_strip_hd.png", "winsor_skyline_hd.png"])
//
//    private var thumbnailPhotoModel: PhotoModel = PhotoCollection(photos: ["barton_nature_leeve.JPG", "barton_nature_area_bridge.JPG", "barton_nature_lake.JPG", "barton_nature_swan.JPG", "bird_hills_nature_tree.JPG", "bird_hills_nature_sunset.JPG", "huron_river.JPG", "bird_hills_nature_foliage.JPG","leslie_park", "willowtree_apartment_sunset.jpg", "vertical_strip.png",  "winsor_skyline.png"])
    
    
    var hdCollectionViewRatio: CGFloat = 0
    var thumbnailCollectionViewThinnestRatio: CGFloat = 0
    var thumbnailCollectionViewThickestRatio: CGFloat = 0
    let thumbnailMaximumWidth:CGFloat = 160
    var flowLayoutSyncManager: FlowLayoutSyncManager!
    private let imageManager = PHCachingImageManager()
    var selectedIndex: Int = 0
    var assets: [PHAsset] = []
    
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
        
        qualityInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.presentDevices(postAction: nil)
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
    }
    
    private func presentDevices(postAction: (() -> ())?) {
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
