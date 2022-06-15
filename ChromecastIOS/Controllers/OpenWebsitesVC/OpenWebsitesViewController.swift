//
//  OpenWebsitesViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 21.04.2022.
//

import UIKit
import RealmSwift

class OpenWebsitesViewController: BaseViewController {

    @IBOutlet weak var backInteractiveView: InteractiveView!
    @IBOutlet weak var websitesCollectionView: UICollectionView!
    @IBOutlet weak var addTabInteractiveView: InteractiveView!
    
    private var tabsNotificationToken: NotificationToken?
    var browserTabs: Results<BrowserTab>!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationSection()
        setupOpenWebsitesCollectionView()
        setupTabsNotificationToken()
        
    }
    
    private func setupOpenWebsitesCollectionView() {
        websitesCollectionView.delegate = self
        websitesCollectionView.dataSource = self
        let size = cellSize()
        websitesCollectionView.contentInset.left = websitesCollectionView.frame.size.width/2 - size.width/2
        let websiteCellNib = UINib(nibName: WebsiteCell.Identifier, bundle: .main)
        websitesCollectionView.register(websiteCellNib, forCellWithReuseIdentifier: WebsiteCell.Identifier)
        websitesCollectionView.contentInset.top = 32
    }
    
    private func setupNavigationSection() {
        
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.navigation?.popViewController(self, animated: true)
        }
        
        addTabInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else {return}
            self.addNewTab()
        }
    }
    
    private func setupTabsNotificationToken() {
        let realm = try! Realm()
        browserTabs = realm.objects(BrowserTab.self).sorted(byKeyPath: #keyPath(BrowserTab.isCurrentTab), ascending: false)
        tabsNotificationToken = browserTabs.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .initial(_):
                break
            case .update(_, _, insertions: let insertions, _):
                self.websitesCollectionView.reloadData()
                if insertions.count > 0 {
                    let item = self.websitesCollectionView.numberOfItems(inSection: 0) - 1
                    let lastItemIndex = IndexPath(item: item, section: 0)
                    self.websitesCollectionView.scrollToItem(at: lastItemIndex, at: .right, animated: true)
                }
            case .error(_):
                break
            }
        }
    }
    
    @objc func addNewTab() {
        let realm = try! Realm()
        let id = UUID().uuidString
        let tab = BrowserTab()
        tab.id = id
        tab.isCurrentTab = false
        try! realm.write {
            realm.add(tab, update: .all)
        }
    }
    
    private func cellSize() -> CGSize {
        let offset: CGFloat = 68 //* SizeFactor // отступы слева/справа/сверху
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
//        let coff = screenHeight/screenWidth
        let cellWidth = screenWidth - offset * 2
        let cellHeight = websitesCollectionView.frame.height - 44//cellWidth * coff //screenHeight - 44 * SizeFactor - offset * 2
        let size = CGSize(width: cellWidth, height: cellHeight)
        return size
    }
    
    private func deleteTab(at indexPath: IndexPath) {
        let tabToRemove = browserTabs[indexPath.row]
        
        if tabToRemove.isCurrentTab {
            //Если удаляем текущую вкладку и она единственная - то просто заменим ее URL и Screenshot дефолтными значениями
            if browserTabs.count == 1 {
                try! tabToRemove.realm?.write {
                    tabToRemove.link = DefaultLocalPage
                    tabToRemove.image = DefaultTabScreenshot
                }
            } else {
                //Если удаляем текущую вкладку, но кроме нее есть еще, то получается у нас есть вкладки 1(Current) и следующая справа вкладка 2.
                //Просто заменю 1.link = 2.link, 1.image = 2.image и удалю 2 из базы
                let firstNextTab = browserTabs[1]
                try! tabToRemove.realm?.write {
                    tabToRemove.link = firstNextTab.link
                    tabToRemove.image = firstNextTab.image
                    tabToRemove.realm?.delete(firstNextTab)
                }
            }
        } else {
            // Если удаляем не текущую вкладку, то просто удаляем
            try! tabToRemove.realm?.write {
                tabToRemove.realm?.delete(tabToRemove)
            }
        }
    }

}

extension OpenWebsitesViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return browserTabs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WebsiteCell.Identifier, for: indexPath) as! WebsiteCell
        let tab = browserTabs[indexPath.row]
         
        if tab.link.hasPrefix("file:///") {
            cell.linkAddressField.text = ""
        } else {
            cell.linkAddressField.text = tab.link
        }
         
        cell.screenImage.image = UIImage(data: tab.image) // ***Change to KingFisher
        cell.didCloseTabTap = { [weak self] in
            guard let self = self else { return }
            self.deleteTab(at: indexPath)
        }
        
        cell.didChooseTabTap = { [weak self] in
            guard let self = self else { return }
            let currentTab = BrowserTab.current
            let tabThatWillBeCurrent = self.browserTabs[indexPath.row]
            try! currentTab.realm?.write {
                currentTab.isCurrentTab = false
                tabThatWillBeCurrent.isCurrentTab = true
            }
            self.navigation?.popViewController(self, animated: true)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
}
