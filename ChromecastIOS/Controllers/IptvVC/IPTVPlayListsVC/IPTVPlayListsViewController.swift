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
        
       
        
        /*
         */
    
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
        if let usersPlaylists = userPlaylists, usersPlaylists.count > 0, indexPath.section == 0 {
            let playlist = usersPlaylists[indexPath.row]
            cell.setup(with: playlist)
            cell.didTouchAction = { [weak self] in
                guard let self = self else { return }
                self.showStreamsListScreen(with: playlist)
            }
        } else if let freePlaylists = freePlaylists, freePlaylists.count > 0 {
            let playlist = freePlaylists[indexPath.row]
            cell.setup(with: playlist)
            cell.didTouchAction = { [weak self] in
                guard let self = self else { return }
                self.showStreamsListScreen(with: playlist)
            }
        }
        return cell
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
