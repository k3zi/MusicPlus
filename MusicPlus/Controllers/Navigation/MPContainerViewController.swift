// 
//  MPContainerViewController.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/12/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

import Foundation

enum PlayerViewStyle {
    case full
    case mini
    case hidden
}

class MPContainerViewController: KZViewController, UINavigationControllerDelegate {

    static let sharedInstance = MPContainerViewController()

    var centerNavigationControllers = [MPNavigationController]()
    var centerViewControllers = [SongsViewController.shared, AlbumsViewController.shared, ArtistsViewController.shared, SettingsViewController.shared, SearchViewController.shared]
    let leftViewController = MPMenuViewController()
    let playerViewController = PlayerViewController.shared

    var xOffsetConstraint: NSLayoutConstraint?

    var currentNavigationController: MPNavigationController?

    var playerViewTopConstraint: NSLayoutConstraint?
    var playerViewStyle: PlayerViewStyle = .hidden {
        didSet {
            if playerViewStyle != .hidden {
                playerViewController.viewWillAppear(true)
            }
            view.bringSubviewToFront(playerViewController.view)
            view.bringSubviewToFront(blurView)

            UIView.animate(withDuration: Constants.UI.Animation.menuSlide, delay: 0.0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                self.playerViewTopConstraint?.autoRemove()

                switch self.playerViewStyle {
                case .mini:
                    self.playerViewTopConstraint = self.playerViewController.miniPlayerView.autoPinEdge(.bottom, to: .bottom, of: self.view)
                    if #available(iOS 11.0, *) {
                        self.centerNavigationControllers.forEach { vc in
                            vc.additionalSafeAreaInsets = .init(top: 0, left: 0, bottom: self.playerViewController.miniPlayerView.bounds.height, right: 0)
                        }
                    }
                case .full:
                    self.playerViewTopConstraint = self.playerViewController.miniPlayerView.autoPinEdge(.bottom, to: .top, of: self.view)
                case .hidden:
                    self.playerViewTopConstraint = self.playerViewController.miniPlayerView.autoPinEdge(.top, to: .bottom, of: self.view)
                    if #available(iOS 11.0, *) {
                        self.centerNavigationControllers.forEach { vc in
                            vc.additionalSafeAreaInsets = .zero
                        }
                    }
                }

                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }

    lazy var blurView: UIView = {
        let view = UIView()
        view.alpha = 0
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.addSubview(blur)
        blur.autoPinEdgesToSuperviewEdges()
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Sidebar
        view.insertSubview(leftViewController.view, at: 0)
        addChild(leftViewController)

        // Main Controllers
        centerNavigationControllers = centerViewControllers.map({
            let vc = MPNavigationController(rootViewController: $0)
            vc.view.layer.shadowOpacity = 0.17
            vc.view.layer.shadowOffset = CGSize(width: -14, height: 0)
            vc.view.layer.shadowColor = UIColor.black.cgColor
            vc.view.layer.shadowRadius = 13
            vc.delegate = self

            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
            vc.view.addGestureRecognizer(panGestureRecognizer)

            vc.view.isHidden = true
            view.addSubview(vc.view)
            addChild(vc)

            vc.view.autoPinEdge(toSuperviewEdge: .top)
            vc.view.autoPinEdge(.left, to: .right, of: leftViewController.view)
            vc.view.autoMatch(.width, to: .width, of: view)
            vc.view.autoPinEdge(toSuperviewEdge: .bottom)
            return vc
        })

        // Player
        view.addSubview(playerViewController.view)
        addChild(playerViewController)
        playerViewController.view.autoPinEdge(.left, to: .right, of: leftViewController.view)
        playerViewController.view.autoMatch(.height, to: .height, of: view, withOffset: .miniPlayerViewHeight)
        playerViewController.view.autoMatch(.width, to: .width, of: view)
        playerViewTopConstraint = playerViewController.miniPlayerView.autoPinEdge(.top, to: .bottom, of: self.view)

        blurView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideMenu)))
        view.addSubview(blurView)
        blurView.autoPinEdge(toSuperviewEdge: .top)
        blurView.autoPinEdge(.left, to: .right, of: leftViewController.view)
        blurView.autoMatch(.width, to: .width, of: view)
        blurView.autoPinEdge(toSuperviewEdge: .bottom)

        if let first = centerNavigationControllers.first {
            currentNavigationController = first
            first.view.isHidden = false

            view.bringSubviewToFront(first.view)
            first.didMove(toParent: self)
        }

        view.bringSubviewToFront(playerViewController.view)
        view.bringSubviewToFront(blurView)
        if #available(iOS 11.0, *) {
            self.centerNavigationControllers.forEach { vc in
                vc.additionalSafeAreaInsets = .zero
            }
        }

        self.view.layoutIfNeeded()

        NotificationCenter.default.addObserver(forName: .didStartNewCollection, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else {
                return
            }

            if self.playerViewStyle == .hidden {
                self.playerViewStyle = .full
            }
        }.dispose(with: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if KZRealmLibrary.libraries.isEmpty {
            self.present(CreateLibraryViewController(), animated: true, completion: nil)
        }
    }

    override func setupConstraints() {
        leftViewController.view.autoPinEdge(toSuperviewEdge: .top)
        leftViewController.view.autoPinEdge(toSuperviewEdge: .bottom)
        xOffsetConstraint = leftViewController.view.autoPinEdge(toSuperviewEdge: .left, withInset: -120)
    }

    @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {

    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    func addMenuItemController(_ itemController: KZViewController) {
        let vc = MPNavigationController(rootViewController: itemController)
        vc.view.layer.shadowOpacity = 0.17
        vc.view.layer.shadowOffset = CGSize(width: -14, height: 0)
        vc.view.layer.shadowColor = UIColor.black.cgColor
        vc.view.layer.shadowRadius = 13

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        vc.view.addGestureRecognizer(panGestureRecognizer)

        vc.view.isHidden = true
        view.addSubview(vc.view)
        addChild(vc)
    }

    // MARK: - Interaction

    @objc func toggleMenu() {
        let isShown = currentNavigationController?.view.frame.origin.x == Constants.UI.Navigation.menuWidth

        if isShown {
            hideMenu()
        } else {
            showMenu()
        }
    }

    func showMenu() {
        leftViewController.view.frame.origin.x = -Constants.UI.Navigation.menuWidth
        UIView.animate(withDuration: Constants.UI.Animation.menuSlide, delay: 0.0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            self.xOffsetConstraint?.constant = 0
            self.view.layoutIfNeeded()
            self.blurView.alpha = 0.5
        }, completion: nil)
    }

    @objc func hideMenu() {
        UIView.animate(withDuration: Constants.UI.Animation.menuSlide, delay: 0.0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            self.xOffsetConstraint?.constant = -Constants.UI.Navigation.menuWidth
            self.view.layoutIfNeeded()
            self.blurView.alpha = 0
        }, completion: nil)
    }

    func switchToNavigationController(_ vc: KZViewController) {
        guard let navigationController = vc.navigationController as? MPNavigationController else {
            return
        }

        let prevNavigationController = currentNavigationController

        guard navigationController != prevNavigationController else {
            return hideMenu()
        }

        navigationController.willMove(toParent: self)
        navigationController.viewWillAppear(true)
        navigationController.view.isHidden = false
        prevNavigationController?.view.isHidden = true
        view.bringSubviewToFront(navigationController.view)
        view.bringSubviewToFront(playerViewController.view)
        view.bringSubviewToFront(blurView)
        navigationController.didMove(toParent: self)
        navigationController.viewDidAppear(true)

        navigationController.view.frame.origin.x = prevNavigationController?.view.frame.origin.x ?? 0

        self.currentNavigationController = navigationController

        let isShown = currentNavigationController?.view.frame.origin.x == Constants.UI.Navigation.menuWidth

        if isShown {
            hideMenu()
        }
    }

    @objc func minimizePlayer() {
        MPContainerViewController.sharedInstance.playerViewStyle = .mini
    }

    @objc func maximizePlayer() {
        MPContainerViewController.sharedInstance.playerViewStyle = .full
    }

    // MARK: - Navigtaion Controller

    @objc func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return MPNavigationAnimatedTransitiion(operation: operation)
    }
}
