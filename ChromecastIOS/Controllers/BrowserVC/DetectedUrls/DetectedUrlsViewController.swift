//
//  DetectedUrlsViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 13.05.2022.
//

import UIKit
import WebKit
import Realm
import RealmSwift
import Kingfisher

class DetectedUrlsViewController: AFFloatingPanelViewController {

    deinit {
        print(">>> deinit DetectedUrlsViewController")
    }
    
    @IBOutlet weak var tableView: UITableView!
     
    var didFinishAction: Closure?
    var castToTVClosure: ((String) -> ())?
    
    private var detectedUrls: Results<DetectedUrl>?
     
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
         */
        
        let realm = try! Realm()
        detectedUrls = realm.objects(DetectedUrl.self)
        
        /*
         */
        
        tableView.delegate = self
        tableView.dataSource = self
        
        /*
         */
        
        let cellNib = UINib(nibName: DetectedUrlCell.Identifier, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: DetectedUrlCell.Identifier)
         
        /*
         */

    }
    
    private func presentDevices(postAction: Closure?) {
        let controller = ListDevicesViewController()
        controller.modalPresentationStyle = .overCurrentContext
        controller.isInteractiveBackground = true
        controller.grabberState = .inside
        controller.grabberColor = UIColor.black.withAlphaComponent(0.8)
        controller.didFinishAction = {
            postAction?()
        }
        present(controller, animated: false, completion: nil)
    }
}

extension DetectedUrlsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return detectedUrls?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DetectedUrlCell.Identifier, for: indexPath) as! DetectedUrlCell
        let urlObj = detectedUrls?[indexPath.row]
        if let object = urlObj, let url = URL(string: object.url) {
            //Когда скрипт находит URL - я скачиваю первый кадр видео и кэширую его в Kingfisher по той же ссылке что и само видео. Поэтому превьюшку можно скачивать просто вот так:
            let defaultVideoImage = KFCrossPlatformImage(named: "defaultVideoImage")
            cell.videoImage.kf.setImage(with: url, placeholder: defaultVideoImage)  
            cell.urlLabel.text = object.url
            let size = ""// object.size.isEmpty ? "" : "(\(object.size))"
            cell.videoFormatLabel.text = "\(object.format) \(size)"
            cell.didTapped = { [weak self] in
                guard let self = self else { return }
                self.castToTVClosure?(object.url)
            }
        }
        return cell
    }
}

