//
//  GoogleDriveViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 21.04.2022.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST

class GoogleDriveViewController: BaseViewController {
    
    @IBOutlet weak var backInteractiveView: InteractiveView!
    @IBOutlet weak var moreActionsInteractiveView: InteractiveView!
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    
    @IBOutlet weak var searchBarContainer: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var dropShadowSeparator: DropShadowView!
    @IBOutlet weak var googleSignInButtonContainer: UIView!
    @IBOutlet weak var googleSignInButtonInteractiveView: InteractiveView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var dataSource: [GTLRDrive_File] = []
    
    private let сellWidth = (UIScreen.main.bounds.width - 48 * SizeFactor) / 3
    
    fileprivate var googleAPIs: GoogleDriveAPI?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupGoogleSignIn()
        setupNavigationSection()
        
        if isUserAlreadySigned() == true {
            googleSignInButtonContainer.isHidden = true
        } else {
            searchBarContainer.isHidden = true
            dropShadowSeparator.isHidden = true
            collectionView.isHidden = true
        }
        
        
        let driveCell = UINib(nibName: GoogleDriveCell.Identifier, bundle: .main)
        collectionView.register(driveCell, forCellWithReuseIdentifier: GoogleDriveCell.Identifier)
        
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 16 * SizeFactor, bottom: 0, right: 16 * SizeFactor)
        collectionView.dataSource = self
        collectionView.delegate = self
        
    }
    
    
    
    private func setupNavigationSection() {
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.navigation?.popViewController(self, animated: true)
        }
        
        moreActionsInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.signOut()
        }
        
        connectInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.presentDevices(postAction: nil)
        }
    }
    
    private func isUserAlreadySigned() -> Bool {
        return GIDSignIn.sharedInstance().hasAuthInKeychain()
    }
    
    private func signOut() {
        GIDSignIn.sharedInstance()?.disconnect()
    }
    
    private func signIn() {
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    
    
    
    private func setupGoogleSignIn() {
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = [kGTLRAuthScopeDrive]
        GIDSignIn.sharedInstance()?.signInSilently()
        
        googleSignInButtonInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.signIn()
        }
    }
    
    private func loadAllFilesAndFolders(){
        self.googleAPIs?.allFilesAndFolders(onCompleted: { (response, error) in
            guard let files = response?.files else { return }
            for file in files {
                print(">>>>>>>>>>>>>>>>>>>>")
                print(">>>filename: \(file.name!) \n>>>mimetype: \(file.mimeType!) \n>>>iconlink: \(file.iconLink!) \n>>>thumbnaillink: \(file.thumbnailLink) \n>>>contentHints.thumbnail \(file.contentHints?.thumbnail?.image) \n>>>webContentLink \(file.webContentLink)\n>>>webViewLink  \(file.webViewLink)\n>>>fileExtension \(file.fileExtension)")
                print(">>>>>>>>>>>>>>>>>>>>")
                self.dataSource.append(file)
            }
            self.collectionView.reloadData()
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
    
    
}

extension GoogleDriveViewController: GIDSignInDelegate {
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let _ = error {
            
        } else {
            print("Authenticate successfully")
            let service = GTLRDriveService()
            service.authorizer = user.authentication.fetcherAuthorizer()
            self.googleAPIs = GoogleDriveAPI(service: service)
            self.loadAllFilesAndFolders()
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Did disconnect to user")
    }
    
}

extension GoogleDriveViewController: GIDSignInUIDelegate {}

extension GoogleDriveViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GoogleDriveCell.Identifier, for: indexPath) as! GoogleDriveCell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? GoogleDriveCell {
            let file = dataSource[indexPath.row]
            
            cell.fileLabel.text = file.name
            cell.dateLabel.text = file.modifiedTime?.date.toString()
            
            if file.mimeType == "application/vnd.google-apps.folder" {
                cell.fileImageView.image = UIImage(named: "folderIcon")!
            } else {
                guard let imageUrlString = file.thumbnailLink else { return }
                guard let imageUrl:URL = URL(string: imageUrlString) else { return }
                guard let imageData = try? Data(contentsOf: imageUrl) else { return }
                cell.fileImageView.image = UIImage(data: imageData)
            }
            
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //temp as
        let file = dataSource[indexPath.row]
        guard let thumbnailLink = file.thumbnailLink else { return }
        ChromeCastService.shared.displayImage(with: URL(string: thumbnailLink)!)
    }
    
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
