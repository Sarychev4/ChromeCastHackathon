//
//  ResumeVideoView.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 18.06.2022.
//

import Foundation
import UIKit
import RealmSwift
import GoogleCast

class ResumeVideoView: InteractiveView {
    
    deinit {
        if timer?.isValid == true {
            timer?.invalidate()
        }
    }
    
    /*
     MARK: - Outlets
     */
    
    var iconImageView: UIImageView?
    private var playerNotificationToken: NotificationToken?
    
    var timer: Timer?
    
    /*
     MARK: - Lifecycle
     */
    
    override func awakeFromNib() {
        super.awakeFromNib()
        /*
         */
        
        setupImageView()
        showHide()
        /*
         */
        
        backgroundColor = .clear
        
        
        let realm = try! Realm()
        if let playerStateObj = realm.objects(PlayerState.self).first {
            playerNotificationToken = playerStateObj.observe { [weak self] changes in
                guard let self = self else { return }
                switch changes {
                case .change(_, _):
                    self.showHide()
                case .error(let error):
                    print(">>> PlayerStateObj An error occurred: \(error)")
                case .deleted:
                    print(">>> PlayerStateObj was deleted.")
                }
            }
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            self.showHide()
        })
    }
    
    private func setupImageView() {
        guard iconImageView == nil else { return }
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: .zero))
        imageView.image = UIImage(named: "resumeVideoPlay")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor(hexString: "24282C") //.black
        addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 24 * SizeFactor).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 24 * SizeFactor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        
        iconImageView = imageView
        
    }
    
    private func showHide() {
        let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
        guard let playerState = remoteMediaClient?.mediaStatus?.playerState.rawValue else {
            self.isHidden = true
            return
        }
        if playerState == 0 || playerState == 1 {
            self.isHidden = true
        } else {
            if playerState == 3 {
                iconImageView?.image = UIImage(named: "resumeVideoPlay")?.withRenderingMode(.alwaysTemplate)
            } else {
                iconImageView?.image = UIImage(named: "resumeVideoPause")?.withRenderingMode(.alwaysTemplate)
            }
            self.isHidden = false
        }
        
        
    }
    
    /*
     /** Constant indicating unknown player state. */
       GCKMediaPlayerStateUnknown = 0,
       /** Constant indicating that the media player is idle. */
       GCKMediaPlayerStateIdle = 1,
       /** Constant indicating that the media player is playing. */
       GCKMediaPlayerStatePlaying = 2,
       /** Constant indicating that the media player is paused. */
       GCKMediaPlayerStatePaused = 3,
       /** Constant indicating that the media player is buffering. */
       GCKMediaPlayerStateBuffering = 4,
       /** Constant indicating that the media player is loading media. */
       GCKMediaPlayerStateLoading = 5,
     */
    
}
