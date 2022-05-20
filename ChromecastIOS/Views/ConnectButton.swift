//
//  ConnectButton.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 19.05.2022.
//

import UIKit
import GoogleCast
import RealmSwift

class ConnectButton: InteractiveView {
    
    deinit {
    
    }
       
    /*
     MARK: - Outlets
     */
     
    var iconImageView: UIImageView?
    private var devicesNotificationToken: NotificationToken?
    
    /*
     MARK: - Lifecycle
     */
    
    override func awakeFromNib() {
        super.awakeFromNib()
        /*
         */
        
        setupImageView()
        
        /*
         */
        
        backgroundColor = .clear
        
       
        let realm = try! Realm()
        let connectedDevices = realm.objects(DeviceObject.self).where { $0.isConnected == true }
        devicesNotificationToken = connectedDevices.observe { [weak self] changes in
            guard let self = self else { return }
            switch changes {
            case .initial(_):
                break
            case .update(_, _, _, _):
                self.setupColor()
                break
            case .error(_):
                break
            }
        }
    }
    
    private func setupImageView() {
        guard iconImageView == nil else { return }
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: .zero))
        imageView.image = UIImage(named: "castIcon")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .black
        addSubview(imageView)
         
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 24 * SizeFactor).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 24 * SizeFactor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        
        iconImageView = imageView
        setupColor()
    }
    
    private func setupColor() {
        let connectionState = GCKCastContext.sharedInstance().sessionManager.connectionState.rawValue
        iconImageView?.tintColor = connectionState == 2 ? .green : .black
    }
    
    /*
     /** Disconnected from the device or application. */
     GCKConnectionStateDisconnected = 0,
     /** Connecting to the device or application. */
     GCKConnectionStateConnecting = 1,
     /** Connected to the device or application. */
     GCKConnectionStateConnected = 2,
     /** Disconnecting from the device. */
     GCKConnectionStateDisconnecting = 3
     */

}
