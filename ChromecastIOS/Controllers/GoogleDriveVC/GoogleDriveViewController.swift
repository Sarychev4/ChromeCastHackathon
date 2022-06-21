//
//  GoogleDriveViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 21.04.2022.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST
import GoogleCast
import ZMJTipView

class GoogleDriveViewController: BaseViewController {
    
    @IBOutlet weak var backInteractiveView: InteractiveView!
    
    @IBOutlet weak var titleLabel: DefaultLabel!
    @IBOutlet weak var moreActionsInteractiveView: InteractiveView!
    
    @IBOutlet weak var resumeVideoInteractiveView: ResumeVideoView!
    @IBOutlet weak var spaceView: UIView!
    
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    
    @IBOutlet weak var searchBarContainer: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var dropShadowSeparator: DropShadowView!
    @IBOutlet weak var googleSignInButtonContainer: UIView!
    @IBOutlet weak var googleSignInButtonInteractiveView: InteractiveView!
    @IBOutlet weak var googleSignInButton: GIDSignInButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var isTipWasShown = false
    private var tipView: ZMJTipView?
    
    private var state: PlaybackState?
    private var selectedIndex: Int = -1
    
    var dataSource: [GTLRDrive_File] = []
    var filteredDataSource: [GTLRDrive_File] = []
    
    var isSubfolder: Bool = false
    var subFolder: String = ""
    var titleOfSubViewController: String = ""
    
    private let сellWidth = (UIScreen.main.bounds.width - 48 * SizeFactor) / 3
    private var shadowAnimator: UIViewPropertyAnimator?
    
    
    fileprivate var googleAPIs: GoogleDriveAPI?
    var isSearchBarIsEmpty: Bool {
        return searchBar.text?.isEmpty ?? false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isSubfolder == false {
            setupGoogleSignIn()
        } else {
            titleLabel.text = titleOfSubViewController
            loadFilesInSpecificFolder(folderName: subFolder)
        }
        
        setupNavigationSection()
        updateUI()
        
        let driveCell = UINib(nibName: GoogleDriveCell.Identifier, bundle: .main)
        collectionView.register(driveCell, forCellWithReuseIdentifier: GoogleDriveCell.Identifier)
        
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 16 * SizeFactor, bottom: 0, right: 16 * SizeFactor)
        collectionView.dataSource = self
        collectionView.delegate = self
         
//        googleSignInButtonInteractiveView.didTouchAction = { [weak self] in
//            guard let self = self else { return }
//            self.signIn()
//        }
        googleSignInButton.style = .wide
        
        setupSearchBar()
        setupShadowAnimation()
        
        setupPlayerStateObserver()
        showHideResumeButton()
        
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
    
    
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.searchTextField.textColor = UIColor.black.withAlphaComponent(0.8)
    }
    
    private func updateUI() {
        if isUserAlreadySigned() == true {
            googleSignInButtonContainer.isHidden = true
            searchBarContainer.isHidden = false
//            dropShadowSeparator.isHidden = false
            collectionView.isHidden = false
        } else {
            googleSignInButtonContainer.isHidden = false
            searchBarContainer.isHidden = true
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
        
        resumeVideoInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.tipView?.isHidden = true
            ChromeCastService.shared.showDefaultMediaVC()
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
    
    private func showHideResumeButton() {
        let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
        guard let playerState = remoteMediaClient?.mediaStatus?.playerState.rawValue else {
            resumeVideoInteractiveView.isHidden = true
            spaceView.isHidden = true
            return
        }
        if playerState == 0 || playerState == 1 {
            resumeVideoInteractiveView.isHidden = true
            spaceView.isHidden = true
        } else {
            resumeVideoInteractiveView.isHidden = false
            spaceView.isHidden = false
        }
    }
    
    private func isUserAlreadySigned() -> Bool {
        return GIDSignIn.sharedInstance.hasPreviousSignIn()
    }
    
    private func signOut() {
        GIDSignIn.sharedInstance.disconnect()
    }
    
    private func signIn() {
        let config = GIDConfiguration(clientID: "719393243681-q159h4ibja392l88iiuba6nb8o8q0qeh.apps.googleusercontent.com")
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [weak self] user, error in
            guard let self = self else { return }
            if let err = error {
//                self.navigation?.popViewController(self, animated: true)
                print(">>> signIn error: \(err.localizedDescription)")
            } else {
                print(">>> Authenticate successfully!")
                
                GIDSignIn.sharedInstance.addScopes(
                    [kGTLRAuthScopeDrive],
                    presenting: self,
                    callback: { user, error in
                        if let err = error {
                            print(err.localizedDescription)
                        } else {
                            print("Scope requested successfully")
                            
                            self.updateUI()
                            let service = GTLRDriveService()
                            service.authorizer = user?.authentication.fetcherAuthorizer()
                            self.googleAPIs = GoogleDriveAPI(service: service)
                            self.loadFilesInRootFolder()
                        }
                    })
            }
        }
    }
    
    private func setupGoogleSignIn() {
        //        GIDSignIn.sharedInstance?.signInSilently()
        
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            guard let self = self else { return }
            if let err = error { 
                print(err.localizedDescription)
            } else {
                print(">>> SIGN in restore")
                self.updateUI()
                let service = GTLRDriveService()
                service.authorizer = user?.authentication.fetcherAuthorizer()
                self.googleAPIs = GoogleDriveAPI(service: service)
                self.loadFilesInRootFolder()
            }
        }
    }
    
    private func loadFilesInRootFolder() {
        activityIndicator.startAnimating()
        self.googleAPIs?.listFiles("root", onCompleted: { [weak self] (response, error) in
            guard let self = self else { return }
            print("Response \(String(describing: response))")
            guard let files = response?.files else { return }
            for file in files {
                print(">>>>>>>>>>>>>>>>>>>>")
                print(">>>id: \(file.identifier!) \n >>>filename: \(file.name!) \n>>>mimetype: \(file.mimeType!) >>>file size: \(file.size) \n>>>iconlink: \(file.iconLink!) \n>>>thumbnaillink: \(file.thumbnailLink) \n>>>contentHints.thumbnail \(file.contentHints?.thumbnail?.image) \n>>>webContentLink \(file.webContentLink)\n>>>webViewLink  \(file.webViewLink)\n>>>fileExtension \(file.fileExtension)")
                print(">>>>>>>>>>>>>>>>>>>>")
//                self.googleAPIs?.shareFile(file, onCompleted: { error in
//                    print("Permissions error: \(error?.localizedDescription)")
//                })
                self.dataSource.append(file)
                self.collectionView.reloadData()
            }
            print(error)
            print(files)
            self.activityIndicator.stopAnimating()
        })
    }
    
    private func loadFilesInSpecificFolder(folderName: String) {
        activityIndicator.startAnimating()
        self.googleAPIs?.search(folderName, onCompleted: { [weak self] (fileItem, error) in
            guard let self = self else { return }
            guard error == nil, fileItem != nil else {
                return
            }
            guard let folderID = fileItem?.identifier else {
                return
            }
            self.googleAPIs?.listFiles(folderID, onCompleted: { [weak self] (response, error) in
                guard let self = self else { return }
                guard let files = response?.files else { return }
                for file in files {
//                    self.googleAPIs?.shareFile(file, onCompleted: { error in
//                        print("Permissions error: \(error?.localizedDescription)")
//                    })
                    self.dataSource.append(file)
                    self.collectionView.reloadData()
                }
                print(error)
                print(files)
                self.activityIndicator.stopAnimating()
            })
        })
    }
    
    private func loadAllFilesAndFolders() {
        activityIndicator.startAnimating()
        self.googleAPIs?.allFilesAndFolders(onCompleted: { [weak self] (response, error) in
            guard let self = self else { return }
            print("All files Response \(response)")
            print("All files error \(error?.localizedDescription)")
            guard let files = response?.files else { return }
            for file in files {
                self.dataSource.append(file)
                self.collectionView.reloadData()
                self.activityIndicator.stopAnimating()
            }
            
        })
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
    
    func handleTapOnCell(with file: GTLRDrive_File, at index: Int) {
        
        guard let fileType = file.mimeType else { return }
        switch fileType {
        case "application/vnd.google-apps.folder":
            guard let fileName = file.name else { return }
            let viewController = GoogleDriveViewController()
            viewController.titleOfSubViewController = fileName
            viewController.hidesBottomBarWhenPushed = true
            viewController.googleAPIs = self.googleAPIs
            viewController.isSubfolder = true
            viewController.subFolder = fileName
            self.navigation?.pushViewController(viewController, animated: .left)
            
        case "image/jpeg", "image/png", "image/jpg":
            self.connectIfNeeded { [weak self] in
                guard let self = self else { return }
                guard let file_id = file.identifier else { return }
                guard let urlWithFileID = URL(string: "https://drive.google.com/uc?id=\(file_id)") else { return }
                self.googleAPIs?.shareFile(file, onCompleted: { error in
                    if let err = error {
                        print("Permissions error: \(err.localizedDescription)")
                    } else {
                        ChromeCastService.shared.displayImage(with: urlWithFileID)
                    }
                })
                
            }
        case "video/mp4":
            self.tipView?.isHidden = true
            self.connectIfNeeded { [weak self] in
                guard let self = self else { return }
                if self.selectedIndex != index && self.state == .paused { //если новая ячейка и ничего не играет
                    self.playVideo(with: file, at: index)
                } else if self.selectedIndex != index && self.state == .playing { //если новая ячейка и видео уже играет
                    self.playVideo(with: file, at: index)
                } else if self.selectedIndex == index && self.state == .paused { //eсли старая ячейка и ничего не играет
                    ChromeCastService.shared.showDefaultMediaVC()
                } else if self.selectedIndex == index && self.state == .playing { //eсли старая ячейка и видео уже играет
                    ChromeCastService.shared.showDefaultMediaVC()
                } else {
                    self.playVideo(with: file, at: index)
                }
            }
        default:
            print(">>>FileType: \(fileType)")
        }
        
       
    }
    
    private func playVideo(with file: GTLRDrive_File, at index: Int) {
        self.connectIfNeeded { [weak self] in
            guard let self = self else { return }
            
            self.selectedIndex = index
            self.state = .playing
            
            guard let file_id = file.identifier,
                  let urlWithFileID = URL(string: "https://drive.google.com/uc?id=\(file_id)"),
                  let imageUrlString = file.thumbnailLink,
                  let previewImageUrl = URL(string: imageUrlString) else { return }
                self.googleAPIs?.shareFile(file, onCompleted: { error in
                    if let err = error {
                        print("Permissions error: \(err.localizedDescription)")
                    } else {
                        if self.isTipWasShown == false {
                            self.resumeVideoInteractiveView.isHidden = false
                            self.spaceView.isHidden = false
                            self.showTipView()
                            self.isTipWasShown = true
                        }
                        ChromeCastService.shared.displayVideo(with: urlWithFileID, previewImage: previewImageUrl)
                        ChromeCastService.shared.showDefaultMediaVC()
                    }
                })
        }
    }
    
    private func showTipView() {
        let preferences = ZMJPreferences()
        preferences.drawing.font = UIFont.systemFont(ofSize: 14)
        preferences.drawing.textAlignment = .center
        preferences.drawing.backgroundColor = UIColor(hexString: "FBBB05")
        preferences.positioning.maxWidth = 130
//        preferences.positioning.bubbleVInset = 34
        preferences.drawing.arrowPosition = .top
        preferences.drawing.arrowHeight = 0
        
        preferences.animating.dismissTransform = CGAffineTransform(translationX: 100, y: 0);
        preferences.animating.showInitialTransform = CGAffineTransform(translationX: 100, y: 0);
        preferences.animating.showInitialAlpha = 0;
        preferences.animating.showDuration = 1;
        preferences.animating.dismissDuration = 1;
        
        let title = NSLocalizedString("Common.ResumeVideo.Tip", comment: "")
        guard let tipView2 = ZMJTipView(text: title, preferences: preferences, delegate: nil) else { return }
        self.tipView = tipView2
        self.tipView?.show(animated: true, for: self.resumeVideoInteractiveView, withinSuperview: nil)
    }
    
    private func setupPlayerStateObserver() {
        ChromeCastService.shared.observePlayerState { state in
            switch state {
            case 1:
                self.spaceView.isHidden = true
                self.state = .stopped
                self.tipView?.isHidden = true
                self.selectedIndex = -1
            case 2:
                self.state = .playing
                self.spaceView.isHidden = false
            case 3:
                self.state = .paused
                self.spaceView.isHidden = false
            default:
                print("")
            }
        }
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
        alert.addAction(UIAlertAction(title: NSLocalizedString("Screen.GoogleDrive.LogOut", comment: ""), style: .destructive, handler: { [weak self] (_) in
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

extension GoogleDriveViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isSearchBarIsEmpty {
            return dataSource.count
        } else {
            print("Filtered Items count:\(filteredDataSource.count)")
            return filteredDataSource.count
        }
        
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GoogleDriveCell.Identifier, for: indexPath) as! GoogleDriveCell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? GoogleDriveCell {
            var file = GTLRDrive_File()
            if filteredDataSource.isEmpty {
                file = dataSource[indexPath.row]
            } else {
                file = filteredDataSource[indexPath.row]
            }
            
            cell.setup(name: file.name, date: file.modifiedTime?.date.toString(), fileSize: file.size, mimeType: file.mimeType, thumbnailLinkString: file.thumbnailLink)
            cell.didChooseCell = { [weak self] in
                    guard let self = self else { return }
                    self.searchBar.endEditing(true)
                self.handleTapOnCell(with: file, at: indexPath.row)
            }
        }
    }
    //14a1vBv3cfvZ--8J11xClnwZB5IUTt0Fr
    //WORKED VIDEO LINK https://drive.google.com/uc?id=14a1vBv3cfvZ--8J11xClnwZB5IUTt0Fr
    //WORKED IMAGE LINK https://drive.google.com/uc?id=1_VdDNwB7yHWU9FCNkFGOM8Ym3XgkUU-_
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: сellWidth, height: 168)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8 * SizeFactor
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8 * SizeFactor
    }
    
}

extension GoogleDriveViewController: UISearchBarDelegate {
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        if text == "" {
            self.searchBar.endEditing(true)
        } else {
           
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.endEditing(true)
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count > 0 {
            filteredDataSource = dataSource.filter { $0.name?.contains(searchText) ?? false}
            collectionView.reloadData()
        } else {
            filteredDataSource.removeAll()
           collectionView.reloadData()
        }
        
    }
    
    
}

//MARK: - Extension ScrollView
extension GoogleDriveViewController: UIScrollViewDelegate {
    
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
