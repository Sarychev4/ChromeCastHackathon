//
//  CellBasicMeasurement.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 22.04.2022.
//

import UIKit

protocol CellBasicMeasurement: AnyObject {
    var currentCellIndex: Int { get }
    var cellMaximumWidth: CGFloat { get }
}

extension CellBasicMeasurement where Self: UICollectionViewLayout {
    var cellMaximumWidth: CGFloat {
        guard let collectionView = collectionView as? CellConfiguratedCollectionView else { return 0 }
        return collectionView.cellMaximumWidth
    }
    
    func cellFullWidth(for indexPath: IndexPath) -> CGFloat {
        guard let collectionView = collectionView as? CellConfiguratedCollectionView else { return 0 }
        return collectionView.cellSize(for: indexPath)?.width ?? 0
    }
    
    var cellFullSpacing: CGFloat {
        guard let collectionView = collectionView as? CellConfiguratedCollectionView else { return 0 }
        return collectionView.cellFullSpacing
    }
    
    var cellNormalWidth: CGFloat {
        guard let collectionView = collectionView as? CellConfiguratedCollectionView else { return 0 }
        return collectionView.cellNormalWidth
    }
    
    var cellNormalSpacing: CGFloat {
        guard let collectionView = collectionView as? CellConfiguratedCollectionView else { return 0 }
        return collectionView.cellNormalSpacing
    }
    
    var cellNormalWidthAndSpacing: CGFloat {
        return cellNormalWidth + cellNormalSpacing
    }
    
    var cellNormalSize: CGSize {
        guard let collectionView = collectionView as? CellConfiguratedCollectionView else { return CGSize.zero }
        return CGSize(width:collectionView.cellNormalWidth, height:collectionView.cellHeight)
    }
    
    var cellHeight: CGFloat {
        guard let collectionView = collectionView as? CellConfiguratedCollectionView else { return 0 }
        return collectionView.cellHeight
    }
    
    var cellCount: Int {
        return collectionView!.dataSource!.collectionView(collectionView!, numberOfItemsInSection: 0)
    }
}
