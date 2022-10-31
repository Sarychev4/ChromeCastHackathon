//
//  MainViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 19.04.2022.
//

import UIKit
import WebKit
import CSSystemInfoHelper
import GoogleCast
import ReplayKit
import SystemConfiguration.CaptiveNetwork 

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
    
    @IBOutlet weak var systemBroadcastPickerView: RPSystemBroadcastPickerView!
//    @IBOutlet weak var settingsInteractiveView: InteractiveView!
    @IBOutlet weak var goToPremiumInteractiveView: InteractiveView!
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mirrorInteractiveView: InteractiveView! 
    @IBOutlet weak var needHelpInteractiveLabel: InteractiveLabel!
    
    
    var tabs: [Tab] = []
    //    var source: String!
    var nameForEvents: String { return "Menu screen" }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        ChromeCastService.shared.initialize()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        connectInteractiveView.didTouchAction = { [weak self] in
            guard self == self else { return }
            
            self?.presentDevices(postAction: nil)
        }
        
        let menuCellNib = UINib(nibName: MainCell.Identifier, bundle: .main)
        collectionView.register(menuCellNib, forCellWithReuseIdentifier: MainCell.Identifier)
        
        collectionView.contentInset.top = 0
        setupTabs()
        setupHelpSection()
        setupMirrorButton()
        setupHeaderSection()
        

    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        try! Settings.current.realm?.write {
//            Settings.current.isIntroCompleted = true
//        }
//        LocalNetworkPermissionsManager.shared.checkUserPermissonsLocalNetwork(onComplete: { (success) in
//            if success {
//
//                ChromeCastService.shared.initialize()
//
//
//
//            } else {
//                self.showAlertLocalNetworkPermissionRequired {
//                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
//
//                    if UIApplication.shared.canOpenURL(settingsURL) {
//                        UIApplication.shared.open(settingsURL, completionHandler: { (success) in
//
//                        })
//                    }
//                }
//            }
//        })
    }
    
    private func showAlertLocalNetworkPermissionRequired(onComplete: (() -> ())?) {
        
        let alertView = AlertViewController(
            alertTitle: NSLocalizedString("Alert.Permissions.Denied.LocalNetwork.Title", comment: ""),
            alertSubtitle: NSLocalizedString("Alert.Permissions.Denied.LocalNetwork.Message", comment: ""),
            continueAction: NSLocalizedString("Alert.Permissions.Denied.LocalNetwork.Continue", comment: ""),
            leftAction: nil,
            rightAction: nil
        )
        
        alertView.continueClicked = {
            onComplete?()
            alertView.dismiss()
        }
        
        alertView.present(from: self)
    }
    
    private func setupMirrorButton() {
        mirrorInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            
            let vc = MirrorViewController()
            vc.hidesBottomBarWhenPushed = true
            self.navigation?.pushViewController(vc, animated: .left)
        }
    }
    
    private func setupHeaderSection() {
        
//        settingsInteractiveView.didTouchAction = { [weak self] in
//        guard let self = self else { return }
//
//            let settingsViewController = SettingsViewController()
//            let navigationController = DefaultNavigationController(rootViewController: settingsViewController)
//            navigationController.modalPresentationStyle = .fullScreen
//            self.present(navigationController, animated: true, completion: nil)
//        }
        
        
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
            type: .googleDrive
        )
        
        let googlePhotos = Tab(
            title: NSLocalizedString("Screen.Main.Tab.GooglePhotos.Title", comment: ""),
            subtitle: NSLocalizedString("Screen.Main.Tab.GooglePhotos.Subtitle", comment: ""),
            image: UIImage(named: "googlePhotos")!,
            type: .googlePhotos
        )
        
        if Settings.current.googleButtonsEnabled {
            tabs = [browser, media, iptv, youtube, googleDrive, googlePhotos]
        } else {
            tabs = [browser, media, iptv, youtube]
        }
        
    }
    
    private func handleTapOnCell(at indexPath: IndexPath) {
        
        if UIScreen.main.isCaptured {
            showAlertStopMirroring()
            return
        }
        
        let buttonType = tabs[indexPath.row].type
        
        switch buttonType {
        case .media:
            let viewController = MediaLibraryViewController()
            viewController.hidesBottomBarWhenPushed = true
            navigation?.pushViewController(viewController, animated: .left)
        case .browser:
            let viewController = BrowserViewController()
            viewController.hidesBottomBarWhenPushed = true
            navigation?.pushViewController(viewController, animated: .left)
        case .iptv:
            let viewController = IPTVPlayListsViewController()
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
    
    private func setupHelpSection() {
        needHelpInteractiveLabel.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.checkInternetConnection {
                let viewController = SetupChromeCastViewController()
                viewController.modalPresentationStyle = .fullScreen
                viewController.hideInteractiveViewCompletion = {
                    viewController.backInteractiveView.isHidden = true
                }
                self.present(viewController, animated: true, completion: nil)
            }
        }
    }
    
    private func presentDevices(postAction: (() -> ())?) {
        let controller = ListDevicesViewController()
        controller.canDismissOnPan = true
        controller.isInteractiveBackground = true
        controller.grabberState = .inside
        controller.grabberColor = UIColor.black.withAlphaComponent(0.8)
        controller.modalPresentationStyle = .overCurrentContext
        controller.didFinishAction = {  [weak self] in
            guard let _ = self else { return }
            postAction?()
        }
        present(controller, animated: false, completion: nil)
    }
    
    private func showAlertStopMirroring() {
        let alertView = AlertViewController(alertTitle: NSLocalizedString("AlertCloseBroadcastTitle", comment: ""),
                                            alertSubtitle: NSLocalizedString("AlertCloseBroadcastSubtitle", comment: ""),
                                            continueAction: nil,
                                            leftAction: NSLocalizedString("AlertCloseBroadcastCancel", comment: ""),
                                            rightAction: NSLocalizedString("AlertCloseBroadcastStop", comment: ""))
        
        alertView.noClicked = { [weak self, weak alertView] in
            guard let _ = self else { return }
            alertView?.dismiss()
        }
        
        alertView.yesClicked = { [weak self, weak alertView] in
            guard let self = self else { return }
            self.systemBroadcastPickerView.preferredExtension = "com.appflair.chromecast.ios.MirroringExtension"
            if let mirroringButton = self.systemBroadcastPickerView.subviews.first(where: { $0 is UIButton }) as? UIButton {
                mirroringButton.sendActions(for: .allTouchEvents)
            }
            alertView?.dismiss()
        }
        
        alertView.present(from: self)
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
        
        let collectionWidth = self.collectionView.bounds.width
        let collectionHeight = self.collectionView.bounds.height
        let cellWidth = (collectionWidth) / 2
        let cellHeight = (collectionHeight) / 3
        var size: CGSize
        size = CGSize(width: cellWidth, height: cellHeight) //146
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}
