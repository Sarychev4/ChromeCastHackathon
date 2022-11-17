//
//  SettingsViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 20.04.2022.
//

import UIKit
import ReplayKit
import RealmSwift
import Network
import Dispatch
import MBProgressHUD
import GoogleCast

class MirrorViewController: BaseViewController {
    
    @IBOutlet weak var backInteractiveView: InteractiveView!
    @IBOutlet weak var connectInteractiveView: InteractiveView!
    
    @IBOutlet weak var rotationSwitch: UISwitch!
    
    @IBOutlet weak var showHideImageView: UIImageView!
    @IBOutlet weak var qualityContainer: UIStackView!
    
    
    @IBOutlet weak var showHideMirrorToImageView: UIImageView!
    @IBOutlet weak var mirrorToContainer: UIStackView!
    
    
    @IBOutlet weak var mirrorToInteractiveView: InteractiveView!
    @IBOutlet weak var mirrorToLabel: DefaultLabel!
    
    @IBOutlet weak var tvInteractiveView: InteractiveView!
    @IBOutlet weak var tvLabel: DefaultLabel!
    @IBOutlet weak var tvImageView: UIImageView!
    
    @IBOutlet weak var pcInteractiveView: InteractiveView!
    @IBOutlet weak var pcLabel: DefaultLabel!
    @IBOutlet weak var pcImageView: UIImageView!
    
    @IBOutlet weak var qualityInteractiveView: InteractiveView!
    @IBOutlet weak var qualityLabel: DefaultLabel!
    
    @IBOutlet weak var optimizedInteractiveView: InteractiveView!
    @IBOutlet weak var optimizedLabel: DefaultLabel!
    @IBOutlet weak var optimizedImageView: UIImageView!
    
    @IBOutlet weak var balancedInteractiveView: InteractiveView!
    @IBOutlet weak var balancedLabel: DefaultLabel!
    @IBOutlet weak var balancedImageView: UIImageView!
    
    @IBOutlet weak var bestInteractiveView: InteractiveView!
    @IBOutlet weak var bestLabel: DefaultLabel!
    @IBOutlet weak var bestImageView: UIImageView!
    
    @IBOutlet weak var needHelpInteractiveLabel: InteractiveLabel!
    
    
    @IBOutlet weak var helpMirroringDescriptionLabel: UILabel!
    
    @IBOutlet weak var streamURLLabel: UILabel!
    
    @IBOutlet weak var broadCastView: RPSystemBroadcastPickerView!
    @IBOutlet weak var mirrorActionLabel: DefaultLabel!
    
    
    var mirroringButton: UIButton? {
        return broadCastView.subviews.first(where: { $0 is UIButton }) as? UIButton
    }
    
    var didFinishAction: Closure?
    
    private var settingsNotificationsToken: NotificationToken?
    private var applicationNotificationToken: NotificationToken!
    private var mirroringStateToken: NotificationToken?
    private var nwPathMonitor: NWPathMonitor?
    
    private var state: MirroringInAppState = .mirroringNotStarted {
        didSet {
            try? Settings.current.realm?.write {
                Settings.current.mirroringState = state
            }
            
            switch state {
            case .mirroringStarted:
                let image = UIImage(named: "TapToStopMirroring")!
                mirroringButton?.setImage(image, for: .normal)
                mirrorActionLabel.text = NSLocalizedString("Screen.Mirror.Action.Tap.Stop", comment: "")
                //                if isDLNADeviceConnected() {
                //                    updateMirroringStreamURL()
                //                }
            case .mirroringNotStarted:
                let image = UIImage(named: "TapToStartMirroring")!
                mirroringButton?.setImage(image, for: .normal)
                mirrorActionLabel.text = NSLocalizedString("Screen.Mirror.Action.Tap.Start", comment: "")
                
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        observeMirroringState()
        setupMirrotingSection()
        setupNavigationSection()
        setupSettingsSection()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelDidGetTapped(sender:)))

        streamURLLabel.isUserInteractionEnabled = true
        streamURLLabel.addGestureRecognizer(tapGesture)
        
        showHideOpenTheURL()
//        helpMirroringDescriptionLabel.isHidden = true
//        streamURLLabel.isHidden = true
     
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        state = Settings.current.mirroringState
    }
    
    @objc private func willEnterForegroundAction() {
        connectIfNeeded(onComplete: nil)
    }
    
    @IBAction func rotationChanged(_ sender: UISwitch) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let isRotationEnabled = sender.isOn
        
        try? StreamConfiguration.current.realm?.write {
            StreamConfiguration.current.isAutoRotate = isRotationEnabled
        }
    }
    
    @IBAction func startBroadcastClicked(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

            
        if StreamConfiguration.current.mirrorToType == .tv {
            switch state {
            case .mirroringNotStarted:
                if GCKCastContext.sharedInstance().sessionManager.connectionState.rawValue == 2 {
                    self.showSystemMirroringScreen()
                } else {
                    presentDevices(postAction: { [weak self] in
                        guard let self = self else { return }
                        self.startBroadcastClicked(sender)
                    })
                }
                print("WWWW")
            case .mirroringStarted:
                print("GGWWW")
                showSystemMirroringScreen()
            }
        } else {
            showSystemMirroringScreen()
            self.showHideOpenTheURL()
        }
            

        
    }
    
    @objc
    func labelDidGetTapped(sender: UITapGestureRecognizer) {
        guard let label = sender.view as? UILabel else {
            return
        }
        UIPasteboard.general.string = label.text
    }
    
    private func connectIfNeeded(onComplete: Closure?) {
        guard GCKCastContext.sharedInstance().sessionManager.connectionState.rawValue != 2 else {
            onComplete?()
            return
        }
        presentDevices {
            onComplete?()
        }
    }
    
    private func setupMirrotingSection() {
        if let mirroringButton = mirroringButton {
            mirroringButton.setImage(nil, for: .normal)
        }
        //temp as
        broadCastView.preferredExtension = "com.appflair.chromecast.ios.MirroringExtension"
        broadCastView.showsMicrophoneButton = false
    }
    
    private func showSystemMirroringScreen() {
        mirroringButton?.sendActions(for: .allTouchEvents)
    }
    
    
    private func setupNavigationSection() {
        backInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.navigation?.popViewController(self, animated: true)
        }
        
        connectInteractiveView.didTouchAction = { [weak self] in
            guard self == self else { return }
            self?.presentDevices(postAction: nil)
        }
    }
    
    private func observeMirroringState() {
        mirroringStateToken = StreamConfiguration.current.observe({ [weak self] (changes) in
            guard let self = self else { return }
            switch changes {
            case .error(_): break
            case .change(_, let properties):
                for property in properties {
                    if property.name == #keyPath(StreamConfiguration.resolutionType) {
                        self.updateUIbasedOnQuality()
                    }
                    
                    if property.name == #keyPath(StreamConfiguration.event),  let value = property.newValue as? String,  let event = StreamEvent(rawValue: value) {
                        switch event {
                        case .broadcastStarted:
                            self.state = .mirroringStarted
                        case .broadcastFinished:
                            self.state = .mirroringNotStarted
                        }
                    }
                }
            case .deleted: break
            }
        })
    }
    
    private func showHideOpenTheURL() {
        if StreamConfiguration.current.mirrorToType == .tv {
            helpMirroringDescriptionLabel.isHidden = true
            streamURLLabel.isHidden = true
            streamURLLabel.text = "https://ovh36.antmedia.io:5443/WebRTCAppEE/player.html"
        } else {
            helpMirroringDescriptionLabel.isHidden = false
            streamURLLabel.isHidden = false
            streamURLLabel.text = "https://ovh36.antmedia.io:5443/WebRTCAppEE/player.html"
        }
    }
    
    private func setupSettingsSection() {
        
        rotationSwitch.isOn = StreamConfiguration.current.isAutoRotate
        
        //Mirror to
        mirrorToContainer.isHidden = true
        
        tvImageView.isHidden = true
        pcImageView.isHidden = true
        
        mirrorToInteractiveView.didTouchAction = {
            if self.mirrorToContainer.isHidden == true {
                self.mirrorToContainer.isHidden = false
                self.showHideMirrorToImageView.image = UIImage(named: "hide")
            } else {
                self.mirrorToContainer.isHidden = true
                self.showHideMirrorToImageView.image = UIImage(named: "show")
            }
            self.qualityContainer.isHidden = true
        }
        
        tvInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            
            try? StreamConfiguration.current.realm?.write {
                StreamConfiguration.current.mirrorToType = .tv
                
            }
            
            
            self.updateUIbasedOnMirrorTo()
            self.mirrorToContainer.isHidden = true
            self.showHideMirrorToImageView.image = UIImage(named: "show")
            self.showHideOpenTheURL()
            
        }
        
        pcInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            
            try? StreamConfiguration.current.realm?.write {
                StreamConfiguration.current.mirrorToType = .pc
            }
            
            self.updateUIbasedOnMirrorTo()
            self.mirrorToContainer.isHidden = true
            self.showHideMirrorToImageView.image = UIImage(named: "show")
            self.showHideOpenTheURL()
        }
        
        //Quality
        qualityContainer.isHidden = true
        
        optimizedImageView.isHidden = true
        balancedImageView.isHidden = true
        bestImageView.isHidden = true
        
        qualityInteractiveView.didTouchAction = {
            if self.qualityContainer.isHidden == true {
                self.qualityContainer.isHidden = false
                self.showHideImageView.image = UIImage(named: "hide")
            } else {
                self.qualityContainer.isHidden = true
                self.showHideImageView.image = UIImage(named: "show")
            }
            self.mirrorToContainer.isHidden = true
        }
        
        optimizedInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            try? StreamConfiguration.current.realm?.write {
                StreamConfiguration.current.resolutionType = .low
            }
            self.updateUIbasedOnQuality()
        }
        
        balancedInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                try? StreamConfiguration.current.realm?.write {
                    StreamConfiguration.current.resolutionType = .medium
                }
                self.updateUIbasedOnQuality()
            }
        }
        
        
        
        bestInteractiveView.didTouchAction = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                try? StreamConfiguration.current.realm?.write {
                    StreamConfiguration.current.resolutionType = .high
                }
                self.updateUIbasedOnQuality()
            }
        }
        
        needHelpInteractiveLabel.didTouchAction = { [weak self] in
            guard let self = self else { return }
            self.checkInternetConnection {
                let viewController = SetupChromeCastViewController()
                viewController.modalPresentationStyle = .fullScreen
                viewController.hideInteractiveViewCompletion = {
                    viewController.backInteractiveView.isHidden = true
                }
                self.present(viewController, animated: true, completion: nil)
            }
        }
        
        
        updateUIbasedOnQuality()
        updateUIbasedOnMirrorTo()
    }
    
    private func updateUIbasedOnMirrorTo(){
        let currentQuality = StreamConfiguration.current.mirrorToType
        switch currentQuality {
        case .tv:
            mirrorToLabel.text = NSLocalizedString("Screen.MirrorTo.TV", comment: "")
            tvImageView.isHidden = false
            pcImageView.isHidden = true
        case .pc:
            mirrorToLabel.text = NSLocalizedString("Screen.MirrorTo.PC", comment: "")
            tvImageView.isHidden = true
            pcImageView.isHidden = false
        default:
            tvImageView.isHidden = false
            pcImageView.isHidden = true
        }
    }
    
    private func updateUIbasedOnQuality(){
        let currentQuality = StreamConfiguration.current.resolutionType
        switch currentQuality {
        case .low:
            qualityLabel.text = NSLocalizedString("Screen.Mirror.Quality.Optimized", comment: "")
            optimizedImageView.isHidden = false
            balancedImageView.isHidden = true
            bestImageView.isHidden = true
        case .medium:
            qualityLabel.text = NSLocalizedString("Screen.Mirror.Quality.Balanced", comment: "")
            balancedImageView.isHidden = false
            optimizedImageView.isHidden = true
            bestImageView.isHidden = true
        case .high:
            qualityLabel.text = NSLocalizedString("Screen.Mirror.Quality.Best", comment: "")
            bestImageView.isHidden = false
            balancedImageView.isHidden = true
            optimizedImageView.isHidden = true
        default:
            optimizedImageView.isHidden = false
            balancedImageView.isHidden = true
            bestImageView.isHidden = true
        }
    }
    
    private func presentDevices(postAction: (() -> ())?) {
        let controller = ListDevicesViewController()
        controller.canDismissOnPan = true
        controller.isInteractiveBackground = true
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
