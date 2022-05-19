//
//  MainViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 19.04.2022.
//

import UIKit
import Agregator
import Criollo
import WebKit
import CSSystemInfoHelper
import GoogleCast

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
                let settingsViewController = SettingsViewController()
                let navigationController = DefaultNavigationController(rootViewController: settingsViewController)
                navigationController.modalPresentationStyle = .fullScreen
                self.present(navigationController, animated: true, completion: nil)
            }
        }
    }
    

    
    
    @IBOutlet weak var goToPremiumInteractiveView: InteractiveView! {
        didSet {
            goToPremiumInteractiveView.didTouchAction = {
                
            #if DEBUG //1
                try! AgregatorApplication.current.realm?.write {
                    if AgregatorApplication.current.subscriptionState == .active {
                        AgregatorApplication.current.subscriptionState = .none
                    } else {
                        AgregatorApplication.current.subscriptionState = .active
                    }
                }//temp vr 1
                return
            #endif
            }
        }
    }
    
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var mirrorInteractiveView: InteractiveView! {
        didSet {
            mirrorInteractiveView.didTouchAction = {
                self.navigation?.pushViewController(MirrorViewController(), animated: .left)
            }
        }
    }
    
    var tabs: [Tab] = []
    //    var source: String!
    var nameForEvents: String { return "Menu screen" }
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var testImageView: UIImageView!
    
    var isFileMngr = false
    
    @IBAction func testCastImageButtonTapped(_ sender: Any) {
//        ChromeCastService.shared.displayImage(with: URL(string: "http://risovach.ru/upload/2014/03/mem/s-dr-karoch_45066550_orig_.jpeg")!)
        // URL(string: "http://localhost:\(Port.app.rawValue)/image")
        //http://127.0.0.1/image.jpeg
        //192.168.1.34
        //scheme://host:port
        //http://192.168.1.34:10101/image.jpeg worked!
        //
        let networkInterfaces = CSSystemInfoHelper.shared.networkInterfaces!
        guard let interface = CSSystemInfoHelper.shared.networkInterfaces?.filter({ $0.name == "en0" && $0.familyName == "AF_INET" }).first else { return }
        let ipAddress = interface.address

        print("MY ADDRESS \(ipAddress)")
        
        guard let url = URL(string: "http://\(ipAddress):\(Port.app.rawValue)/video/\(UUID().uuidString)") else { return }
        ChromeCastService.shared.displayIPTVBeam(with: url)

        let request = URLRequest(url: URL(string: "http://\(ipAddress):\(Port.app.rawValue)/video/:id")!)
        webView.load(request)
        
        print(ChromeCastService.shared.screenMirroringChannel ?? "CHANNEL IS DEAD")
        
        testImageView.image = loadImageFromDiskWith(fileName: "imageForCasting.jpeg")
    }
    
    func loadImageFromDiskWith(fileName: String) -> UIImage? {

      let documentDirectory = FileManager.SearchPathDirectory.documentDirectory

        let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)

        if let dirPath = paths.first {
            let imageUrl = URL(fileURLWithPath: dirPath).appendingPathComponent(fileName)
            let image = UIImage(contentsOfFile: imageUrl.path)
            return image

        }

        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ChromeCastService.shared.initialize()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        connectInteractiveView.didTouchAction = { [weak self] in
            guard self == self else { return }
            self?.presentDevices(postAction: nil)
            print(">>>STATE \(GCKCastContext.sharedInstance().sessionManager.connectionState.rawValue)")
        }
        
        let menuCellNib = UINib(nibName: MainCell.Identifier, bundle: .main)
        collectionView.register(menuCellNib, forCellWithReuseIdentifier: MainCell.Identifier)
        
        collectionView.contentInset.top = 0
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
            type: .googleDrive
        )
        
        let googlePhotos = Tab(
            title: NSLocalizedString("Screen.Main.Tab.GooglePhotos.Title", comment: ""),
            subtitle: NSLocalizedString("Screen.Main.Tab.GooglePhotos.Subtitle", comment: ""),
            image: UIImage(named: "googlePhotos")!,
            type: .googlePhotos
        )
        
        tabs = [browser, media, iptv, youtube, googleDrive, googlePhotos]
    }
    
    private func handleTapOnCell(at indexPath: IndexPath) {
        
        let buttonType = tabs[indexPath.row].type
        
        switch buttonType {
        case .media:
            let viewController = MediaLibraryViewController()
            viewController.hidesBottomBarWhenPushed = true
            //                       viewController.flowLayoutSyncManager = FlowLayoutSyncManager()
            navigation?.pushViewController(viewController, animated: .left)
            
            //            let viewController = MediaViewController()
            //            viewController.hidesBottomBarWhenPushed = true
            //            viewController.flowLayoutSyncManager = FlowLayoutSyncManager() //temp as important
            //            navigation?.pushViewController(viewController, animated: .left)
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
