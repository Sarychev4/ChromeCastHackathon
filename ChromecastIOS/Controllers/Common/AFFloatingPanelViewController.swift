//
//  AFFloatingPanelViewController.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 26.04.2022.
//

import UIKit

public enum AFFloatingPanelGrabberState {
    case outside, inside
    
    internal var containerHeightConstraint: CGFloat {
        let map: [AFFloatingPanelGrabberState : CGFloat] = [.outside : 80 * SizeFactor,
                                                            .inside: 32 * SizeFactor]
        return map[self]!
    }
    
    internal var containerTopConstraint: CGFloat {
        let map: [AFFloatingPanelGrabberState : CGFloat] = [.outside : -18 * SizeFactor,
                                                            .inside: 0]
        return map[self]!
    }
    
    internal var grabberTopConstraint: CGFloat {
        let map: [AFFloatingPanelGrabberState : CGFloat] = [.outside : 6 * SizeFactor,
                                                            .inside: 10 * SizeFactor]
        return map[self]!
    }
}

@objc
public enum AFFloatingPanelState: Int {
    case full = 0
    case hidden
}

@objc
public protocol AFFloatingPanelDelegate: AnyObject {
    @objc
    optional func floatingPanelDidClose(_ floatingPanel: AFFloatingPanelViewController)
    @objc
    optional func floatingPanelWillBeginDragging(_ floatingPanel: AFFloatingPanelViewController)
    @objc
    optional func floatingPanelDidEndDragging(_ floatingPanel: AFFloatingPanelViewController, targetPosition: AFFloatingPanelState)
}

fileprivate let Delta: CGFloat = 0.25
fileprivate let GrabberViewHeight: CGFloat = 4 * SizeFactor
fileprivate let GrabberViewWidth: CGFloat = 40 * SizeFactor
fileprivate let PanelViewPart: Int = 3

open class AFFloatingPanelViewController: BaseViewController {
    
    /*
     MARK: -
     */
    
    @IBOutlet public weak var panelView: UIView!
    @IBOutlet weak var panelViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet public weak var panelViewContentBottomConstraint: NSLayoutConstraint?
   
    
    /*
     MARK: -
     */
    
    public weak var delegate: AFFloatingPanelDelegate?
    public var isGrabberHidden = false {
        didSet {
            grabberViewContainer?.isHidden = isGrabberHidden
        }
    }
    public var isInteractiveBackground = true {
        didSet {
            backgroundView?.isUserInteractionEnabled = isInteractiveBackground
        }
    }
    
    public var state: AFFloatingPanelState = .full
    public var grabberState: AFFloatingPanelGrabberState = .inside
    public var panelViewHeight: CGFloat = 0
    public var radius: CGFloat = DefaultCornerRadius
    public var grabberColor: UIColor? = .clear
    public var canDismissOnPan: Bool = true
    
    private var panelViewStartBottomPosition: CGFloat = 0
    private var contentViewBottomPadding: CGFloat = 0
    
    private var backgroundView: DefaultView!
    private var grabberViewContainer: DefaultView!
    
    /*
     MARK: - Init and setup
     */
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        setupBackgroundView()
        setupGrabberView()
        
        panelView.backgroundColor = .white

        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(dragPopover(_:)))
        panelView.addGestureRecognizer(dragGesture)
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        present()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        panelViewHeight = panelView.bounds.height
        panelViewBottomConstraint.constant = -(panelViewHeight)
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        panelView.roundCorners([.topLeft, .topRight], radius: radius)
    }
    
    /*
     MARK: Hide logic
     */
    open func hidePanel(with completion: Closure?) {
        panelViewBottomConstraint.constant = -(panelViewHeight + view.layoutMargins.bottom)
        
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseIn], animations: {
            self.view.layoutIfNeeded()
            self.backgroundView.alpha = 0
        }) { [weak self] (_) in
            guard let self = self else { return }
            self.dismiss(animated: false, completion: {
                self.delegate?.floatingPanelDidClose?(self)
                completion?()
            })
        }
    }
    
    /*
     MARK: Present logic
     */
    private func present() {
        panelViewBottomConstraint.constant = 0
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            self.view.layoutIfNeeded()
            self.backgroundView.alpha = 0.7
        }, completion: nil)
    }
    
    /*
     MARK: UI functions
     */
    private func setupBackgroundView() {
        backgroundView = DefaultView()
        backgroundView.backgroundColor = UIColor.clear
        backgroundView.alpha = 0
        backgroundView.isUserInteractionEnabled = isInteractiveBackground
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hide))
        backgroundView.addGestureRecognizer(tapGesture)
        
        view.addSubview(backgroundView)
        view.sendSubviewToBack(backgroundView)
        
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
    }
    
    private func setupGrabberView() {
        grabberViewContainer = DefaultView()
        grabberViewContainer.backgroundColor = UIColor.clear
        grabberViewContainer.isUserInteractionEnabled = true
        grabberViewContainer.isHidden = isGrabberHidden
        view.addSubview(grabberViewContainer)
        
        grabberViewContainer.translatesAutoresizingMaskIntoConstraints = false
        grabberViewContainer.topAnchor.constraint(equalTo: panelView.topAnchor, constant: grabberState.containerTopConstraint).isActive = true
        grabberViewContainer.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: 0).isActive = true
        grabberViewContainer.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: 0).isActive = true
        grabberViewContainer.heightAnchor.constraint(equalToConstant: grabberState.containerHeightConstraint).isActive = true
        
        let grabberView = RoundedView()
        grabberView.backgroundColor = grabberColor
        grabberView.clipsToBounds = true
        grabberViewContainer.addSubview(grabberView)
        
        grabberView.translatesAutoresizingMaskIntoConstraints = false
        grabberView.topAnchor.constraint(equalTo: grabberViewContainer.topAnchor, constant: grabberState.grabberTopConstraint).isActive = true
        grabberView.centerXAnchor.constraint(equalTo: grabberViewContainer.centerXAnchor, constant: 0).isActive = true
        grabberView.heightAnchor.constraint(equalToConstant: GrabberViewHeight).isActive = true
        grabberView.widthAnchor.constraint(equalToConstant: GrabberViewWidth).isActive = true
        
        let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(dragPopover(_:)))
        grabberViewContainer.addGestureRecognizer(dragGesture)
    }
    
    /*
     MARK: Gesture recognizers functions
     */
    @objc
    private func hide() {
        hidePanel(with: nil)
    }

    @objc
    private func dragPopover(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            panelViewStartBottomPosition = panelViewBottomConstraint.constant
            contentViewBottomPadding = panelViewContentBottomConstraint?.constant ?? 0
            delegate?.floatingPanelWillBeginDragging?(self)
        case .changed:
            let translation = gesture.translation(in: panelView)
            let yPosition = panelViewStartBottomPosition - translation.y
            
            switch yPosition {
            case let x where x > 0:
                let position = yPosition * Delta
                panelViewContentBottomConstraint?.constant = contentViewBottomPadding + position
            default:
                panelViewBottomConstraint.constant = yPosition
            }
        case .cancelled, .ended:
            let translation = gesture.translation(in: panelView)
            let yPosition = panelViewStartBottomPosition - translation.y
            
            switch yPosition {
            case let x where x < -(panelViewHeight / CGFloat(PanelViewPart))  && canDismissOnPan:
                hidePanel(with: nil)
                state = .hidden
            default:
                panelViewBottomConstraint.constant = 0
                panelViewContentBottomConstraint?.constant = contentViewBottomPadding
                
                UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
                    self.view.layoutSubviews()
                }, completion: nil)
                
                state = .full
            }
            
            delegate?.floatingPanelDidEndDragging?(self, targetPosition: state)
        default:
            break
        }
    }

}
