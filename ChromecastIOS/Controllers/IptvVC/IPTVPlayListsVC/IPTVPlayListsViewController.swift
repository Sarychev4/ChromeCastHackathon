//
//  IPTVPlayListsViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 21.04.2022.
//

import UIKit
import RealmSwift

class IPTVPlayListsViewController: BaseViewController {

    deinit {
        print(">>> deinit IPTVPlayListsViewController")
    }
    
    @IBOutlet weak var navigationBarShadowView: DropShadowView!
    @IBOutlet weak var backInteractiveView: InteractiveView!
    @IBOutlet weak var addCategoryInteractiveView: InteractiveView!
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var iptvService = IPTVManager()
    private var freePlaylistsObserver: NotificationToken?
    private var userPlaylistsObserver: NotificationToken?
    private var userPlaylists: Results<PlaylistM3U8>?
    private var freePlaylists: Results<PlaylistM3U8>?
    private var navigationBarAnimator: UIViewPropertyAnimator?
    private var animator: ScrollViewAnimator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        let cell = UINib(nibName: IPTVPlayListCell.Identifier, bundle: .main)
        tableView.register(cell, forCellReuseIdentifier: IPTVPlayListCell.Identifier)
        
        /*
         */
       
        observeFreeStreams()
        
        /*
         */
        
        observeUserStreams()
        
        /*
         */
        
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.navigation?.popViewController(self, animated: true)
        }
        
        addCategoryInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.stopEditing()
            self.showAlertForNewPlayList()
        }
        
        connectInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.presentDevices(postAction: nil)
        }
        
        /*
         */

        if freePlaylists?.count == 0 {
            activityIndicator.startAnimating()
        }

        iptvService.getListIPTV { [weak self] in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
        }
        
        /*
         */
        setupNavigationAnimations()
        
        searchBar.searchTextField.textColor = UIColor(named: "labelColorDark")
        
        /*
         */
    
    }
    
    private func showAlertForNewPlayList() {
        let title = NSLocalizedString("IPTVAddTitle", comment: "")
        let alertController = UIAlertController(title: title, message: "", preferredStyle: .alert)
        let addAction = UIAlertAction(title: NSLocalizedString("IPTVAddSave", comment: ""), style: .default) { [weak self] (action) in
            guard let self = self, let playlistName = alertController.textFields?[0].text, let url = alertController.textFields?[1].text else { return }
            self.iptvService.createIPTV(with: playlistName, playlistURL: url) { [weak self] success in
                guard let _ = self else { return }
                if success == false {
                    print(">>> Failed add playlist")
                }
            }
        }
        alertController.addAction(addAction)

        let cancelAction = UIAlertAction(title: NSLocalizedString("IPTVAddCancel", comment: ""), style: .cancel) { _ in }
        alertController.addAction(cancelAction)
        
        alertController.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("IPTVAddPlaylistName", comment: "")
        }
        alertController.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("IPTVAddPlaylistLink", comment: "")
        }
        present(alertController, animated: true, completion: nil)
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
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            navigationBarAnimator?.stopAnimation(true)
            if navigationBarAnimator?.state != .inactive {
                navigationBarAnimator?.finishAnimation(at: .current)
            }
        }
    }
    
    private func observeFreeStreams() {
        freePlaylists = IPTVManager.realm
            .objects(PlaylistM3U8.self)
            .filter("\(#keyPath(PlaylistM3U8.isUserStream)) == false")
            .sorted(by: [SortDescriptor(keyPath: #keyPath(PlaylistM3U8.priority), ascending: false),
                         SortDescriptor(keyPath: #keyPath(PlaylistM3U8.name), ascending: true)])
        
        freePlaylistsObserver = freePlaylists?.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .initial(_): break
            case .update(_, deletions: _, insertions: _, modifications: _):
                self.tableView.reloadData()
            case .error(_): break
            }
        }
    }
    
    private func observeUserStreams() {
        userPlaylists = IPTVManager.realm
            .objects(PlaylistM3U8.self)
            .filter("\(#keyPath(PlaylistM3U8.isUserStream)) == true")
            .sorted(by: [SortDescriptor.init(keyPath: #keyPath(PlaylistM3U8.priority), ascending: false),
                         SortDescriptor.init(keyPath: #keyPath(PlaylistM3U8.name), ascending: true)])
        
        userPlaylistsObserver = IPTVManager.realm.objects(PlaylistM3U8.self).observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .initial(_): break
            case .update(_, deletions: _, insertions: _, modifications: _):
                self.tableView.reloadData()
            case .error(_): break }
        }
    }
    
    private func showStreamsListScreen(with playlist: PlaylistM3U8) {
        let controller = IPTVStreamsViewController()
        controller.playlistId = playlist.id
        navigation?.pushViewController(controller, animated: .left)
    }
    
    private func stopEditing() {
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
        }
        tableView.reloadData()
    }
    
}

extension IPTVPlayListsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var usersPlaylistSection = 0
        if let userPlaylists = userPlaylists, userPlaylists.count > 0 {
            usersPlaylistSection = 1
        }
        let freePlaylistSection = 1
        return usersPlaylistSection + freePlaylistSection
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let usersPlaylists = userPlaylists, usersPlaylists.count > 0, section == 0 {
            return usersPlaylists.count
        }
        return freePlaylists?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: IPTVPlayListCell.Identifier, for: indexPath) as! IPTVPlayListCell
        cell.sectionNameView.isHidden = indexPath.row != 0
        if let usersPlaylists = userPlaylists, usersPlaylists.count > 0, indexPath.section == 0 {
            let playlist = usersPlaylists[indexPath.row]
            cell.sectionNameLabel.text = NSLocalizedString("IPTVSectionTitleUser", comment: "")
            cell.editButton.alpha = searchBar.text?.isEmpty == false ? 0 : 1
            if tableView.isEditing {
                cell.editButton.setTitle(NSLocalizedString("IPTVDoneTitle", comment: ""), for: .normal)
            } else {
                cell.editButton.setTitle(NSLocalizedString("IPTVEditTitle", comment: ""), for: .normal)
            }
            
            cell.setup(with: playlist)
            cell.didTouchAction = { [weak self] in
                guard let self = self else { return }
                self.showStreamsListScreen(with: playlist)
            }
            cell.didEditAction = { [weak self] in
                guard let self = self else { return }
                self.tableView.setEditing(!self.tableView.isEditing, animated: true)
                self.tableView.reloadData()
            }
        } else if let freePlaylists = freePlaylists, freePlaylists.count > 0 {
            let playlist = freePlaylists[indexPath.row]
            cell.sectionNameLabel.text = NSLocalizedString("IPTVSectionTitleFree", comment: "")
            cell.setup(with: playlist)
            cell.didTouchAction = { [weak self] in
                guard let self = self else { return }
                self.showStreamsListScreen(with: playlist)
            }
        }
        return cell
    }
    
}

extension IPTVPlayListsViewController: UIScrollViewDelegate {
    private func setupNavigationAnimations() {
        navigationBarShadowView.alpha = 0
        navigationBarAnimator = UIViewPropertyAnimator(duration: 1.0, curve: .easeIn, animations: { [weak self] in
            guard let self = self else { return }
            self.navigationBarShadowView.alpha = 1
        })
        animator = ScrollViewAnimator(minAnchor: 0, maxAnchor: 50, animator: navigationBarAnimator!)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPosition = scrollView.contentOffset.y + scrollView.contentInset.top
        animator?.handleAnimation(with: currentPosition)
    }
}

extension IPTVPlayListsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        freePlaylists = IPTVManager.realm
            .objects(PlaylistM3U8.self)
            .filter("\(#keyPath(PlaylistM3U8.isUserStream)) == false")
            .sorted(by: [SortDescriptor(keyPath: #keyPath(PlaylistM3U8.priority), ascending: false),
                         SortDescriptor(keyPath: #keyPath(PlaylistM3U8.name), ascending: true)])
        
        userPlaylists = IPTVManager.realm
            .objects(PlaylistM3U8.self)
            .filter("\(#keyPath(PlaylistM3U8.isUserStream)) == true")
            .sorted(by: [SortDescriptor.init(keyPath: #keyPath(PlaylistM3U8.priority), ascending: false),
                         SortDescriptor.init(keyPath: #keyPath(PlaylistM3U8.name), ascending: true)])
          
        if searchText.count > 0 {
            freePlaylists = freePlaylists?.filter("\(#keyPath(PlaylistM3U8.name)) CONTAINS[cd] '\(searchText)'")
            userPlaylists = userPlaylists?.filter("\(#keyPath(PlaylistM3U8.name)) CONTAINS[cd] '\(searchText)'")
        }

        stopEditing()
    }
}
