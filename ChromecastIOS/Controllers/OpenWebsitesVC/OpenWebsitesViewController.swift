//
//  OpenWebsitesViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 21.04.2022.
//

import UIKit

class OpenWebsitesViewController: BaseViewController {

    @IBOutlet weak var backInteractiveView: InteractiveView!
    @IBOutlet weak var websitesCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        websitesCollectionView.delegate = self
        websitesCollectionView.dataSource = self
        let size = cellSize()
        websitesCollectionView.contentInset.left = websitesCollectionView.frame.size.width/2 - size.width/2
        
        let websiteCellNib = UINib(nibName: WebsiteCell.Identifier, bundle: .main)
        websitesCollectionView.register(websiteCellNib, forCellWithReuseIdentifier: WebsiteCell.Identifier)
        
        websitesCollectionView.contentInset.top = 32
        
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.navigation?.popViewController(self, animated: true)
        }
    }
    
    
    private func cellSize() -> CGSize {
        let offset: CGFloat = 68 * SizeFactor // отступы слева/справа/сверху
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let coff = screenHeight/screenWidth
        let cellWidth = screenWidth - offset * 2
        let cellHeight = cellWidth * coff //screenHeight - 44 * SizeFactor - offset * 2
        let size = CGSize(width: cellWidth, height: cellHeight)
        return size
    }

}

extension OpenWebsitesViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = websitesCollectionView.dequeueReusableCell(withReuseIdentifier: WebsiteCell.Identifier, for: indexPath) as! WebsiteCell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
}
