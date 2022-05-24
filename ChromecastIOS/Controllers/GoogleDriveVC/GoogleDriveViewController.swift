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
    
    @IBOutlet weak var titleLabel: DefaultLabel!
    @IBOutlet weak var moreActionsInteractiveView: InteractiveView!
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    
    @IBOutlet weak var searchBarContainer: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var dropShadowSeparator: DropShadowView!
    @IBOutlet weak var googleSignInButtonContainer: UIView!
    @IBOutlet weak var googleSignInButtonInteractiveView: InteractiveView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var dataSource: [GTLRDrive_File] = []
    var isSubfolder: Bool = false
    var subFolder: String = ""
    var titleOfSubViewController: String = ""
    
    private let сellWidth = (UIScreen.main.bounds.width - 48 * SizeFactor) / 3
    
    fileprivate var googleAPIs: GoogleDriveAPI?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isSubfolder == false {
            setupGoogleSignIn()
        } else {
            self.titleLabel.text = self.titleOfSubViewController
            self.loadFilesInSpecificFolder(folderName: subFolder)
        }
        
        setupNavigationSection()
        updateUI()
        
        let driveCell = UINib(nibName: GoogleDriveCell.Identifier, bundle: .main)
        collectionView.register(driveCell, forCellWithReuseIdentifier: GoogleDriveCell.Identifier)
        
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 16 * SizeFactor, bottom: 0, right: 16 * SizeFactor)
        collectionView.dataSource = self
        collectionView.delegate = self
        
    }
    
    private func updateUI() {
        if isUserAlreadySigned() == true {
            googleSignInButtonContainer.isHidden = true
            searchBarContainer.isHidden = false
            dropShadowSeparator.isHidden = false
            collectionView.isHidden = false
        } else {
            googleSignInButtonContainer.isHidden = false
            searchBarContainer.isHidden = true
            dropShadowSeparator.isHidden = true
            collectionView.isHidden = true
        }
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
                print(err.localizedDescription)
            } else {
                print("Authenticate successfully!")
                
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
        
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let err = error {
                print(err.localizedDescription)
            } else {
                print("SIGN in restore")
                self.updateUI()
                let service = GTLRDriveService()
                service.authorizer = user?.authentication.fetcherAuthorizer()
                self.googleAPIs = GoogleDriveAPI(service: service)
                self.loadFilesInRootFolder()
            }
        }
        
        googleSignInButtonInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.signIn()
        }
    }
    
    private func loadFilesInRootFolder() {
        self.googleAPIs?.listFiles("root", onCompleted: { (response, error) in
            print("Response \(response)")
            guard let files = response?.files else { return }
            for file in files {
                print(">>>>>>>>>>>>>>>>>>>>")
                print(">>>id: \(file.identifier!) \n >>>filename: \(file.name!) \n>>>mimetype: \(file.mimeType!) >>>file size: \(file.size) \n>>>iconlink: \(file.iconLink!) \n>>>thumbnaillink: \(file.thumbnailLink) \n>>>contentHints.thumbnail \(file.contentHints?.thumbnail?.image) \n>>>webContentLink \(file.webContentLink)\n>>>webViewLink  \(file.webViewLink)\n>>>fileExtension \(file.fileExtension)")
                print(">>>>>>>>>>>>>>>>>>>>")
                self.dataSource.append(file)
                self.collectionView.reloadData()
            }
            print(error)
            print(files)
        })
    }
    
    private func loadFilesInSpecificFolder(folderName: String) {
        self.googleAPIs?.search(folderName, onCompleted: { (fileItem, error) in
            guard error == nil, fileItem != nil else {
                return
            }
            guard let folderID = fileItem?.identifier else {
                return
            }
            self.googleAPIs?.listFiles(folderID, onCompleted: { (response, error) in
                guard let files = response?.files else { return }
                for file in files {
                    print(">>>>>>>>>>>>>>>>>>>>")
                    print(">>>id: \(file.identifier!) \n>>>filename: \(file.name!) \n>>>mimetype: \(file.mimeType!) >>>file size: \(file.size) \n>>>iconlink: \(file.iconLink!) \n>>>thumbnaillink: \(file.thumbnailLink) \n>>>contentHints.thumbnail \(file.contentHints?.thumbnail?.image) \n>>>webContentLink \(file.webContentLink)\n>>>webViewLink  \(file.webViewLink)\n>>>fileExtension \(file.fileExtension)")
                    print(">>>>>>>>>>>>>>>>>>>>")
                    self.dataSource.append(file)
                    self.collectionView.reloadData()
                }
                print(error)
                print(files)
            })
        })
    }
    
    private func loadAllFilesAndFolders() {
        self.googleAPIs?.allFilesAndFolders(onCompleted: { (response, error) in
            print("All files Response \(response)")
            print("All files error \(error?.localizedDescription)")
            guard let files = response?.files else { return }
            for file in files {
                
                print(">>>>>>>>>>>>>>>>>>>>")
                print(">>>id: \(file.identifier!) \n>>>filename: \(file.name!) \n>>>mimetype: \(file.mimeType!)\n>>>file size: \(file.size) \n>>>iconlink: \(file.iconLink!) \n>>>thumbnaillink: \(file.thumbnailLink) \n>>>contentHints.thumbnail \(file.contentHints?.thumbnail?.image) \n>>>webContentLink \(file.webContentLink)\n>>>webViewLink  \(file.webViewLink)\n>>>fileExtension \(file.fileExtension)")
                print(">>>>>>>>>>>>>>>>>>>>")
                self.dataSource.append(file)
                self.collectionView.reloadData()
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
    
    func handleTapOnCell(at indexPath: IndexPath) {
        
        guard let name = dataSource[indexPath.row].name else { return }
        
        let viewController = GoogleDriveViewController()
        viewController.titleOfSubViewController = name
        viewController.hidesBottomBarWhenPushed = true
        viewController.googleAPIs = self.googleAPIs
        viewController.isSubfolder = true
        viewController.subFolder = name
        self.navigation?.pushViewController(viewController, animated: .left)
    }
    
    
}

//extension GoogleDriveViewController: GIDSignInUIDelegate {}

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
            
            
            if let fileSize = file.size {
                cell.dataSizeLabel.text = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .memory)
            } else {
                cell.dataSizeLabel.isHidden = true
            }
            
            
            if file.mimeType == "application/vnd.google-apps.folder" {
                cell.fileImageView.image = UIImage(named: "folderIcon")!
                cell.didChooseCell = { [weak self] in
                    guard let self = self else { return }
                    self.handleTapOnCell(at: indexPath)
                }
            } else {
                guard let imageUrlString = file.thumbnailLink else { return }
                guard let imageUrl:URL = URL(string: imageUrlString) else { return }
                guard let imageData = try? Data(contentsOf: imageUrl) else { return }
                cell.fileImageView.image = UIImage(data: imageData)
                cell.didChooseCell = { [weak self] in
                    guard let file_id = file.identifier else { return }
                    guard let mimeType = file.mimeType else { return }
                    //temp as
                    if mimeType == "image/jpeg" {
                        ChromeCastService.shared.displayImage(with: URL(string: "https://drive.google.com/uc?id=\(file_id)")!)
                    } else if mimeType == "video/mp4" {
                        ChromeCastService.shared.displayVideo(with: URL(string: "https://drive.google.com/uc?id=\(file_id)")!)
                    } else {
                        //temp as
                        guard let thumbnailImageLink = file.thumbnailLink else { return }
                        ChromeCastService.shared.displayImage(with: URL(string: thumbnailImageLink)!)
                    }
                }
            }
        }
    }
    //14a1vBv3cfvZ--8J11xClnwZB5IUTt0Fr
    //WORKED VIDEO LINK https://drive.google.com/uc?id=14a1vBv3cfvZ--8J11xClnwZB5IUTt0Fr
    //WORKED IMAGE LINK https://drive.google.com/uc?id=1_VdDNwB7yHWU9FCNkFGOM8Ym3XgkUU-_
    
    //https://docs.google.com/document/d/FILE_ID/export?format=doc
    //image/jpeg
    //testlink  https://docs.google.com/document/d/1_VdDNwB7yHWU9FCNkFGOM8Ym3XgkUU-_/export?format=image/jpeg
    //    >>>webContentLink https://drive.google.com/uc?id=FILE_ID&export=download
    //    >>>webViewLink  https://drive.google.com/file/d/FILE_ID/view?usp=drivesdk
    //          //https://drive.google.com/file/d/1_VdDNwB7yHWU9FCNkFGOM8Ym3XgkUU-_/view
    //        //https://drive.google.com/uc?export=view&id=1_VdDNwB7yHWU9FCNkFGOM8Ym3XgkUU-_
    //        //https://drive.google.com/file/d/1_VdDNwB7yHWU9FCNkFGOM8Ym3XgkUU-_/view?usp=drivesdk
    //        //https://drive.google.com/uc?id=1fKKOVct2v0c5lvY0h1PnQBECL70cBq-t&export=download
    //https://drive.google.com/file/d/1_VdDNwB7yHWU9FCNkFGOM8Ym3XgkUU-_/view?usp=sharing
    //        ChromeCastService.shared.displayImage(with: URL(string: "https://drive.google.com/file/d/1_VdDNwB7yHWU9FCNkFGOM8Ym3XgkUU-_/view?usp=drivesdk")!)
    ////    https://drive.google.com/file/d/14a1vBv3cfvZ--8J11xClnwZB5IUTt0Fr/view?usp=sharing
    //        //https://drive.google.com/file/d/14a1vBv3cfvZ--8J11xClnwZB5IUTt0Fr/view?usp=drivesdk
    //        //https://drive.google.com/uc?id=14a1vBv3cfvZ--8J11xClnwZB5IUTt0Fr&export=download
    //
    ////        ChromeCastService.shared.displayIPTVBeam(with: URL(string: "https://doc-0k-74-docs.googleusercontent.com/docs/securesc/7m5gmj65d2fuu6t3fpe0o9cu8ob1fpmi/8sepu34kss45hqjurj2qr9naqa2soafc/1652545725000/17616169246755069778/17616169246755069778/14a1vBv3cfvZ--8J11xClnwZB5IUTt0Fr?ax=ACxEAsbZXgDlF42WKcZH4oUvXnMq0ZExA4QoCue1Kmg3EiOMBAAwFOKjqfygT11dndkK3-nfwp3rHLoErKa4G9XYQx8GmJ2Efq_BGw0y_fwRYiyJ2pNrEDPfekYpYHkpKMMAAIo8toqsWTdKUQ_g2tvAU01hS1Z_Nz6FtSEe12D6_zzBbkC36iUU9RNpbAb9XT-dR39EUKc5j-o7uRW845uXoR9fQMyJjobv7Lz-JXP8oSXELUtebi8SNHIGqUj_XV_Cc_pKfx_JwqpevtY2wXNTRjlwgJTvnTaQBmNB2g5R9lrLRZ2LBgeFwJSYI4BoSb0tU96SzcZcxZJPp-2nbz1pDFlReEoAUkajz-c2I-cw6TLQDGaXs6a4P2AA4byTrmhMA-ujyoseF_GHf1nn5krGU-IgTbqtkfz-c8EK9v5pFxVeGTBvm70Rc5PlCQcSH8aGNdKKHNFavabFY6lPGIaP115B-va2ZXjSZIaZA5GysSiei7RoB6TQ6CN1NJ0AzhfZcoG5J7Bivwwn2Mz6FzwsiFTvR_mATxidT01IHEj9g-T8hVAGG8OpecTezhbYapjBNPobpQYuRBvBvM85y_AQ4WQGXKksGSXyIxCN0IR0fTZTR78ANakjf1hZR512T0EzZ068zgPvxTodigShIrzCeDfYaxua5wJ4oAqYs1uesYbRBkx2MDuR3YVtpLXyTrVFXf9zAW2sJQUy8vO65NpeekRSMkkQiEZJH7jg1lJ4oLwFoLEjEMQ&authuser=0")!)
    //
    //
    //    }
    
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
