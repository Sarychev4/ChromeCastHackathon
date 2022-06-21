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

class GoogleDriveViewController: BaseViewController {
    
    @IBOutlet weak var backInteractiveView: InteractiveView!
    
    @IBOutlet weak var titleLabel: DefaultLabel!
    @IBOutlet weak var moreActionsInteractiveView: InteractiveView!
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    
    @IBOutlet weak var searchBarContainer: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var dropShadowSeparator: DropShadowView!
    @IBOutlet weak var googleSignInButtonContainer: UIView!
    @IBOutlet weak var googleSignInButtonInteractiveView: InteractiveView!
    @IBOutlet weak var googleSignInButton: GIDSignInButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
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
        
        moreActionsInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            //            self.signOut()
            self.showActionSheet()
        }
        
        connectInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.presentDevices(postAction: nil)
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
    
    func handleTapOnCell(with file: GTLRDrive_File) {
        
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
            self.connectIfNeeded { [weak self] in
                guard let self = self else { return }
            guard let file_id = file.identifier,
                  let urlWithFileID = URL(string: "https://drive.google.com/uc?id=\(file_id)"),
                  let imageUrlString = file.thumbnailLink,
                  let previewImageUrl = URL(string: imageUrlString) else { return }
                self.googleAPIs?.shareFile(file, onCompleted: { error in
                    if let err = error {
                        print("Permissions error: \(err.localizedDescription)")
                    } else {
                        ChromeCastService.shared.displayVideo(with: urlWithFileID, previewImage: previewImageUrl)
                        ChromeCastService.shared.showDefaultMediaVC()
                    }
                })
                
            }
        default:
            print(">>>FileType: \(fileType)")
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
                    self.handleTapOnCell(with: file)
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
