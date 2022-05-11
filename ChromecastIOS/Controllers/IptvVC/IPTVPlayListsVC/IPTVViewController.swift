//
//  IPTVViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 21.04.2022.
//

import UIKit

class IPTVCategoryViewController: BaseViewController {

    deinit {
        print(">>> deinit IPTVViewController")
    }
    
    @IBOutlet weak var backInteractiveView: InteractiveView!
    @IBOutlet weak var addCategoryInteractiveView: InteractiveView!
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        let cell = UINib(nibName: IPTVCategoryCell.Identifier, bundle: .main)
        tableView.register(cell, forCellReuseIdentifier: IPTVCategoryCell.Identifier)
    
    }
    
}

extension IPTVViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: IPTVCategoryCell.Identifier, for: indexPath) as! IPTVCategoryCell
        return cell
    }
    
}
