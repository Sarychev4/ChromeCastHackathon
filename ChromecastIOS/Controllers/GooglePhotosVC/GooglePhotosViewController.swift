//
//  GooglePhotosViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 21.04.2022.
//

import UIKit
import GoogleCast
import GPhotos
import GoogleSignIn

class GooglePhotosViewController: BaseViewController {
    
    @IBOutlet weak var backInteractiveView: InteractiveView!
    
    @IBOutlet weak var titleLabel: DefaultLabel!
    @IBOutlet weak var moreActionsInteractiveView: InteractiveView!
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    
    @IBOutlet weak var dropShadowSeparator: DropShadowView!
    @IBOutlet weak var googleSignInButtonContainer: UIView!
    @IBOutlet weak var googleSignInButtonInteractiveView: InteractiveView!
    @IBOutlet weak var googleSignInButton: GIDSignInButton!
        
    @IBOutlet weak var albumsScrollView: UIScrollView!
    @IBOutlet weak var albumsStackView: UIStackView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var itemsDataSource = [MediaItem]()
    var albumsDataSource = [Album]()
    private var albumViewsArray: [GoogleAlbumView] = []
    private var albumIndex: Int = 0 {
        didSet {
            updateAlbumStackViewUI()
        }
    }
    
    private let сellWidth = (UIScreen.main.bounds.width - 48 * SizeFactor) / 3
    private var shadowAnimator: UIViewPropertyAnimator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initGphotos()
        
        setupGoogleSignIn()
        setupNavigationSection()
        updateUI()
        setupShadowAnimation()
        
        albumsScrollView.contentInset = UIEdgeInsets(top: 0, left: 16 * SizeFactor, bottom: 0, right: 16 * SizeFactor)
        
        let gphotoCell = UINib(nibName: GooglePhotoCell.Identifier, bundle: .main)
        collectionView.register(gphotoCell, forCellWithReuseIdentifier: GooglePhotoCell.Identifier)
        
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 16 * SizeFactor, bottom: 0, right: 16 * SizeFactor)
        collectionView.dataSource = self
        collectionView.delegate = self
        
//        googleSignInButtonInteractiveView.didTouchAction = { [weak self] in
//            guard let self = self else { return }
//            self.signIn()
//        } 
        googleSignInButton.style = .wide
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
    
    private func initGphotos() {
        var config = Config()
        config.printLogs = true
        config.printNetworkLogs = false
        config.automaticallyAskPermissions = false
        GPhotos.initialize(with: config)
    }
    
    private func updateAlbumStackViewUI() {
        for (index, view) in albumViewsArray.enumerated() {
            view.isSelected = index == albumIndex
        }
    }
    
    
    private func updateUI() {
        if isUserAlreadySigned() == true {
            googleSignInButtonContainer.isHidden = true
//            dropShadowSeparator.isHidden = false
            collectionView.isHidden = false
        } else {
            googleSignInButtonContainer.isHidden = false
//            dropShadowSeparator.isHidden = true
            collectionView.isHidden = true
        }
    }
    
    private func setupNavigationSection() {
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
//            ChromeCastService.shared.stopWebApp()
            self.navigation?.popViewController(self, animated: true)
        }
        
        moreActionsInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.showActionSheet()
        }
        
        connectInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.presentDevices(postAction: nil)
        }
    }
    
    
    
    private func isUserAlreadySigned() -> Bool {
        return GPhotos.isAuthorized
    }
    
    private func signOut() {
        GPhotos.logout()
    }
    
    private func signIn() {
        let scopes: Set = [AuthScope.readAndAppend]
        GPhotos.authorize(with: scopes) { [weak self] success, error in
            guard let self = self else { return }
            if let error = error {
//                self.navigation?.popViewController(self, animated: true)
                print ("Authorize error: \(error.localizedDescription)")
            } else {
                self.updateUI()
                self.loadAllAlbums()
                self.loadAllItems()
                self.updateAlbumStackViewUI()
            }
        }
    } 
    
    private func setupGoogleSignIn() {
        print("GPhotos.isAuthorized  \(GPhotos.isAuthorized)")
        if GPhotos.isAuthorized {
            loadAllAlbums()
            loadAllItems()
        }
    }
    
    private func loadAllAlbums() {
        GPhotosApi.albums.reloadList { albums in
            for album in albums {
                self.albumsDataSource.append(album)
            }
            self.setupAlbums()
        }
    }
    
    private func setupAlbums() {
        albumViewsArray.forEach({ $0.removeFromSuperview(); albumsStackView.removeArrangedSubview($0) })
        albumViewsArray.removeAll()
        
        
        var albums = albumsDataSource
        
        let recentAlbum = Album()
        recentAlbum.id = "recentAlbumID"
        recentAlbum.title = "Recents"
        albums.insert(recentAlbum, at: 0)
        
        for (index, album) in albums.enumerated() {
            
            let view = GoogleAlbumView()
            view.titleLabel.text = album.title
            view.containerInteractiveView.didTouchAction = { [weak self] in
                guard let self = self else { return }
                self.clearItemsDataSource()
                self.collectionView.reloadData()
                if album.id == "recentAlbumID" {
                    self.loadAllItems()
                } else {
                    self.loadItemsOfSpecificAlbum(albumID: album.id)
                }
                self.albumIndex = index
            }
            self.albumsStackView.addArrangedSubview(view)
            self.albumViewsArray.append(view)
        }
        updateAlbumStackViewUI()
    }
    
    private func loadItemsOfSpecificAlbum(albumID: String) {
        activityIndicator.startAnimating()
        let request = MediaItemsSearch.Request(albumId: albumID, filters: nil)
        GPhotosApi.mediaItems.reloadSearch(with: request) { items in
            for item in items {
                guard let metaData = item.mediaMetadata else { return }
                if metaData.video == nil {
                    self.itemsDataSource.append(item)
                }
            }
            self.activityIndicator.stopAnimating()
            self.collectionView.reloadData()
        }
    }
    
    private func clearItemsDataSource() {
        self.itemsDataSource = []
    }
    
    
    private func loadAllItems() {
        activityIndicator.startAnimating()
        GPhotosApi.mediaItems.reloadList { [weak self] items in
            guard let self = self else { return }
            for item in items {
                guard let metaData = item.mediaMetadata else { return }
                if metaData.video == nil {
                    self.itemsDataSource.append(item)
                }
                
            }
            self.activityIndicator.stopAnimating()
            self.collectionView.reloadData()
        }
    }
    
    func handleTapOnCell(with item: MediaItem) {
        guard let url = item.baseUrl else { return }
        
        self.connectIfNeeded { [weak self] in
            guard let _ = self else { return }
            if item.mediaMetadata?.photo == nil {
                ChromeCastService.shared.displayVideo(with: url)
                ChromeCastService.shared.showDefaultMediaVC()
                
            } else {
                ChromeCastService.shared.displayImage(with: url)
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
    
    private func connectIfNeeded(onComplete: Closure?) {
        guard GCKCastContext.sharedInstance().sessionManager.connectionState.rawValue != 2 else {
            onComplete?()
            return
        }
        presentDevices {
            onComplete?()
        }
    }
    
    func showActionSheet() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.overrideUserInterfaceStyle = UIUserInterfaceStyle.light
        alert.addAction(UIAlertAction(title: NSLocalizedString("Screen.GooglePhotos.LogOut", comment: ""), style: .destructive, handler: { [weak self] (_) in
            guard let self = self else { return }
            self.signOut()
            self.navigation?.popViewController(self, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Common.Cancel", comment: ""), style: .cancel, handler: { (_) in
            
        }))
        
        self.present(alert, animated: true, completion: {
            
        })
    }
    
    @IBAction func googleSignInClicked(_ sender: Any) {
        signIn()
    }
}

extension GooglePhotosViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GooglePhotoCell.Identifier, for: indexPath) as! GooglePhotoCell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? GooglePhotoCell {
            let item = itemsDataSource[indexPath.row]
            cell.setup(mimeType: item.mimeType, thumbnailLinkString: item.baseUrl?.absoluteString, metaData: item.mediaMetadata)
            cell.didChooseCell = { [weak self] in
                guard let self = self else { return }
                self.handleTapOnCell(with: item)
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
    
}

//MARK: - Extension ScrollView
extension GooglePhotosViewController: UIScrollViewDelegate {
    
    private func setupShadowAnimation() {
        dropShadowSeparator.alpha = 0
        shadowAnimator = UIViewPropertyAnimator(duration: 0.1, curve: .easeOut, animations: { [weak self] in
            guard let self = self else { return }
            self.dropShadowSeparator.alpha = 1.0
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
