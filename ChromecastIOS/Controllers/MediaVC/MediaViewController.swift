//
//  MediaViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 21.04.2022.
//

import UIKit
import AudioToolbox

class MediaViewController: BaseViewController {

    @IBOutlet weak var hdCollectionView: CellConfiguratedCollectionView!
    @IBOutlet weak var thumbnailCollectionView: CellConfiguratedCollectionView!
    
    private var hdPhotoModel: PhotoModel = PhotoCollection(photos: ["barton_nature_leeve_hd.JPG", "barton_nature_area_bridge_hd.JPG", "barton_nature_lake_hd.JPG", "barton_nature_swan_hd.JPG", "bird_hills_nature_tree_hd.JPG", "bird_hills_nature_sunset_hd.JPG", "huron_river_hd.JPG", "bird_hills_nature_foliage_hd.JPG","leslie_park_hd.png", "willowtree_apartment_sunset_hd.jpg", "vertical_strip_hd.png", "winsor_skyline_hd.png"])
    
    private var thumbnailPhotoModel: PhotoModel = PhotoCollection(photos: ["barton_nature_leeve.JPG", "barton_nature_area_bridge.JPG", "barton_nature_lake.JPG", "barton_nature_swan.JPG", "bird_hills_nature_tree.JPG", "bird_hills_nature_sunset.JPG", "huron_river.JPG", "bird_hills_nature_foliage.JPG","leslie_park", "willowtree_apartment_sunset.jpg", "vertical_strip.png",  "winsor_skyline.png"])
    
    var hdCollectionViewRatio: CGFloat = 0
    var thumbnailCollectionViewThinnestRatio: CGFloat = 0
    var thumbnailCollectionViewThickestRatio: CGFloat = 0
    let thumbnailMaximumWidth:CGFloat = 160
    var flowLayoutSyncManager: FlowLayoutSyncManager!
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let layout = thumbnailCollectionView.collectionViewLayout as? ThumbnailFlowLayoutDraggingBehavior {
            layout.unfoldCurrentCell()
        }
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

extension MediaViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case hdCollectionView:
            return hdPhotoModel.numberOfPhotos()
        case thumbnailCollectionView:
            return thumbnailPhotoModel.numberOfPhotos()
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case hdCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HDCell.Identifier, for: indexPath) as! HDCell
            if let image = hdPhotoModel.photo(at: indexPath.row),
               let size = self.collectionView(hdCollectionView, sizeForItemAt: indexPath) {
                cell.photoWidthConstraint.constant = size.width
                cell.photoHeightConstraint.constant = size.height
                cell.clipsToBounds = true
                cell.photoImageView?.contentMode = .scaleAspectFit
                cell.photoImageView?.image = image
            }
            return cell
        case thumbnailCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ThumbnailCell.Identifier, for: indexPath) as! ThumbnailCell
            if let image = thumbnailPhotoModel.photo(at: indexPath.row) {
                cell.photoHeightConstraint.constant = 49
                cell.photoWidthConstraint.constant = 23
                cell.clipsToBounds = true
                cell.photoImageView.contentMode = .scaleAspectFit
                cell.photoImageView.image = image
            }
            return cell
        default:
            return UICollectionViewCell()
        }
    }
}
//MARK: - CollectionView Delegate

extension MediaViewController: UICollectionViewDelegate {
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
            let layout = collectionView.collectionViewLayout as? ThumbnailFlowLayoutDraggingBehavior{
            layout.unfoldCurrentCell()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate,
            let collectionView = scrollView as? UICollectionView,
            let layout = collectionView.collectionViewLayout as? ThumbnailFlowLayoutDraggingBehavior{
            layout.unfoldCurrentCell()
        }
    }
}

//MARK: - CollectionViewCellSize Protocol
extension MediaViewController: CollectionViewCellSize {
    func collectionView(_ collectionView: UICollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize? {
        switch collectionView {
        case hdCollectionView:
            if let size = hdPhotoModel.photoSize(at: indexPath.row) {
                return cellSize(forHDImage: size)
            }
        case thumbnailCollectionView:
            if let size = thumbnailPhotoModel.photoSize(at: indexPath.row) {
                return cellSize(forThumbImage: size)
            }
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

