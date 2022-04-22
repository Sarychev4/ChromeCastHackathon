//
//  MainViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 19.04.2022.
//

import UIKit

struct Tab {
    var title: String
    var subtitle: String
    var image: UIImage
    var type: MenuButtonType
}

enum MenuButtonType {
    case browser, media, iptv, youtube, googleDrive, googlePhotos
}

class MainViewController: BaseViewController {
    
    @IBOutlet weak var settingsInteractiveView: InteractiveView! {
        didSet {
            settingsInteractiveView.didTouchAction = {
                let vc = SettingsViewController()
                vc.modalPresentationStyle = .automatic//.fullScreen
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var mirrorInteractiveView: InteractiveView! {
        didSet {
            mirrorInteractiveView.didTouchAction = {
                self.navigation?.pushViewController(MirrorViewController(), animated: .left)
            }
        }
    }
    
    var tabs: [Tab] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let menuCellNib = UINib(nibName: MainCell.Identifier, bundle: .main)
        collectionView.register(menuCellNib, forCellWithReuseIdentifier: MainCell.Identifier)
        
        collectionView.contentInset.top = 20
        setupTabs()
    }
    
    private func setupTabs() {
        let browser = Tab(
            title: NSLocalizedString("Screen.Main.Tab.Browser.Title", comment: ""),
            subtitle: NSLocalizedString("Screen.Main.Tab.Browser.Subtitle", comment: ""),
            image: UIImage(named: "browser")!,
            type: .browser
        )
        
        let media = Tab(
            title: NSLocalizedString("Screen.Main.Tab.MediaLibrary.Title", comment: ""),
            subtitle: NSLocalizedString("Screen.Menu.Tab.MediaLibrary.Subtitle", comment: ""),
            image: UIImage(named: "media")!,
            type: .media
        )
        
        let iptv = Tab(
            title: NSLocalizedString("Screen.Main.Tab.IPTV.Title", comment: ""),
            subtitle: NSLocalizedString("Screen.Menu.Tab.IPTV.Subtitle", comment: ""),
            image: UIImage(named: "iptv")!,
            type: .iptv
        )
        
        let youtube = Tab(
            title: NSLocalizedString("Screen.Main.Tab.Youtube.Title", comment: ""),
            subtitle: NSLocalizedString("Screen.Menu.Tab.Youtube.Subtitle", comment: ""),
            image: UIImage(named: "youtube")!,
            type: .youtube
        )
        
        let googleDrive = Tab(
            title: NSLocalizedString("Screen.Main.Tab.GoogleDrive.Title", comment: ""),
            subtitle: NSLocalizedString("Screen.Main.Tab.GoogleDrive.Subtitle", comment: ""),
            image: UIImage(named: "googleDrive")!,
            type: .youtube
        )
        
        let googlePhotos = Tab(
            title: NSLocalizedString("Screen.Main.Tab.GooglePhotos.Title", comment: ""),
            subtitle: NSLocalizedString("Screen.Main.Tab.GooglePhotos.Subtitle", comment: ""),
            image: UIImage(named: "googlePhotos")!,
            type: .youtube
        )
        
        tabs = [browser, media, iptv, youtube, googleDrive, googlePhotos]
    }
    
    private func handleTapOnCell(at indexPath: IndexPath) {
        
        let buttonType = tabs[indexPath.row].type
        
        switch buttonType {
        case .media:
            let viewController = MediaViewController()
            viewController.hidesBottomBarWhenPushed = true
            navigation?.pushViewController(viewController, animated: .left)
        case .browser:
            let viewController = BrowserViewController()
            viewController.hidesBottomBarWhenPushed = true
            navigation?.pushViewController(viewController, animated: .left)
        case .iptv:
            let viewController = IPTVViewController()
            viewController.hidesBottomBarWhenPushed = true
            self.navigation?.pushViewController(viewController, animated: .left)
        case .youtube:
            let viewController = YouTubeViewController()
            viewController.hidesBottomBarWhenPushed = true
            self.navigation?.pushViewController(viewController, animated: .left)
        case .googleDrive:
            let viewController = GoogleDriveViewController()
            viewController.hidesBottomBarWhenPushed = true
            self.navigation?.pushViewController(viewController, animated: .left)
        case .googlePhotos:
            let viewController = GooglePhotosViewController()
            viewController.hidesBottomBarWhenPushed = true
            self.navigation?.pushViewController(viewController, animated: .left)
        }
    }
    
}

extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tabs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MainCell.Identifier, for: indexPath) as! MainCell
        let tab = tabs[indexPath.row]
        cell.titleLabel.text = tab.title
        cell.subtitleLabel.text = tab.subtitle
        cell.imageView.image =  tab.image
        cell.type = tab.type
        cell.showControllerAction = { [weak self] in
            guard let self = self else { return }
            self.handleTapOnCell(at: indexPath)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let collectionWidth = self.collectionView.bounds.width//UIScreen.main.bounds.width - 32
        let cellWidth = (collectionWidth) / 2
        
        var size: CGSize //(width: cellWidth, height: cellWidth )//+ 10 * SizeFactor)
        //        if Device.current.isOneOf(Device.allDevicesWithSensorHousing + Device.allSimulatorDevicesWithSensorHousing) {
        //            size = CGSize(width: cellWidth, height: cellWidth )
        //        } else {
        //            size = CGSize(width: cellWidth, height: cellWidth - 10 * SizeFactor )
        //        }
        size = CGSize(width: cellWidth, height: 146 )
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}
