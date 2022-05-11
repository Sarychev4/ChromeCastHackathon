//
//  IPTVStreamsViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 11.05.2022.
//

import UIKit
import RealmSwift

class IPTVStreamsViewController: BaseViewController {

    deinit {
        print(">>> deinit IPTVStreamsViewController")
    }
    
    @IBOutlet weak var backInteractiveView: InteractiveView!
    @IBOutlet weak var navigationTitleLabel: DefaultLabel!
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var playlistId: String!
    
    private var playlist: PlaylistM3U8?
    private var streams: Results<IPTVStream>?
    private var navigationBarAnimator: UIViewPropertyAnimator?
    private var animator: ScrollViewAnimator?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        let cell = UINib(nibName: IPTVStreamCell.Identifier, bundle: .main)
        tableView.register(cell, forCellReuseIdentifier: IPTVStreamCell.Identifier)
        
        /*
         */
        
        playlist = IPTVManager.realm.object(ofType: PlaylistM3U8.self, forPrimaryKey: playlistId)
        
        /*
         */
        
        streams = playlist?.streams.sorted(byKeyPath: #keyPath(IPTVStream.name), ascending: true)
        
        /*
         */
        
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.navigation?.popViewController(self, animated: true)
        }
        
        /*
         */
        
        navigationTitleLabel.text = playlist?.name
    }


}

extension IPTVStreamsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return streams?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: IPTVStreamCell.Identifier, for: indexPath) as! IPTVStreamCell
        if let stream = streams?[indexPath.row] {
            cell.setup(with: stream)
            cell.didTouchAction = { [weak self] in
                guard let self = self else { return }
                self.didSelectCell(at: indexPath)
            }
        }
        return cell
    }
    
    func didSelectCell(at indexPath: IndexPath) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        SubscriptionSpotsManager.shared.requestSpot(for: DataManager.SubscriptionSpotType.iptv.rawValue, with: { [weak self] success in
            guard let _ = self, success == true else { return }
                //запустить стрим
        
        })
    }
    
}

extension IPTVStreamsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        streams = playlist?.streams.sorted(byKeyPath: #keyPath(IPTVStream.name), ascending: true)
        if searchText.count > 0 {
            streams = streams?.filter("\(#keyPath(IPTVStream.name)) CONTAINS[cd] '\(searchText)'")
        }
        tableView.reloadData()
    }
}
