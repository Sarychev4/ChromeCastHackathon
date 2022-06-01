//
//  GooglePhotosViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 21.04.2022.
//

import UIKit
import GPhotos
import GoogleCast

class GooglePhotosViewController: BaseViewController {
    
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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var dataSource: [Int] = []
    var isSubfolder: Bool = false
    var subFolder: String = ""
    var titleOfSubViewController: String = ""
    
    private let сellWidth = (UIScreen.main.bounds.width - 48 * SizeFactor) / 3
    
    var filteredDataSource: [Int] = []
    fileprivate var googleAPIs: GoogleDriveAPI?
    var isSearchBarIsEmpty: Bool {
        return searchBar.text?.isEmpty ?? false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setupGoogleSignIn()
       
        
        setupNavigationSection()
        updateUI()
        
        let driveCell = UINib(nibName: GoogleDriveCell.Identifier, bundle: .main)
        collectionView.register(driveCell, forCellWithReuseIdentifier: GoogleDriveCell.Identifier)
        
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 16 * SizeFactor, bottom: 0, right: 16 * SizeFactor)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        
        
        setupSearchBar()
    }
    

    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.searchTextField.textColor = UIColor.black.withAlphaComponent(0.8)
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
            //            self.signOut()
            self.showActionSheet()
        }
        
        connectInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.presentDevices(postAction: nil)
        }
    }
    
    private func isUserAlreadySigned() -> Bool {
        
        return true
    }
    
    private func signOut() {
        
    }
    
    private func signIn() {
        
    }
    
    private func setupGoogleSignIn() {
       
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
    
//    func handleTapOnCell(with file: GTLRDrive_File) {
//
//    }
    
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
    
    
}

extension GooglePhotosViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
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
    
//    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        if let cell = cell as? GoogleDriveCell {
//            var file = GTLRDrive_File()
//            if filteredDataSource.isEmpty {
//                file = dataSource[indexPath.row]
//            } else {
//                file = filteredDataSource[indexPath.row]
//            }
//
//            cell.setup(name: file.name, date: file.modifiedTime?.date.toString(), fileSize: file.size, mimeType: file.mimeType, thumbnailLinkString: file.thumbnailLink)
//            cell.didChooseCell = { [weak self] in
//                    guard let self = self else { return }
//                    self.searchBar.endEditing(true)
//                    self.handleTapOnCell(with: file)
//            }
//        }
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

extension GooglePhotosViewController: UISearchBarDelegate {
    
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
    
    
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        if searchText.count > 0 {
//            filteredDataSource = dataSource.filter { $0.name?.contains(searchText) ?? false}
//            collectionView.reloadData()
//        } else {
//           collectionView.reloadData()
//        }
//
//    }
    
    
}
