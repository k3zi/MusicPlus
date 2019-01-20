// 
//  MPContainerViewController.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/12/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
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
    var centerViewControllers = [SongsViewController.shared, AlbumsViewController.shared, ArtistsViewController.shared, SettingsViewController.shared]
    let leftViewController = MPMenuViewController()
    let playerViewController = PlayerViewController.shared

    var xOffsetConstraint: NSLayoutConstraint?

    var currentNavigationController: MPNavigationController?

    var playerViewTopConstraint: NSLayoutConstraint?
    var playerViewStyle: PlayerViewStyle = .hidden {
        didSet {
            view.bringSubviewToFront(playerViewController.view)

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
            vc.view.layer.shadowColor = RGB(0).cgColor
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
        playerViewController.view.autoMatch(.height, to: .height, of: view, withOffset: 50)
        playerViewController.view.autoMatch(.width, to: .width, of: view)
        playerViewTopConstraint = playerViewController.miniPlayerView.autoPinEdge(.top, to: .bottom, of: self.view)

        if let first = centerNavigationControllers.first {
            currentNavigationController = first
            first.view.isHidden = false

            view.bringSubviewToFront(first.view)
            first.didMove(toParent: self)
        }

        view.bringSubviewToFront(playerViewController.view)
        if #available(iOS 11.0, *) {
            self.centerNavigationControllers.forEach { vc in
                vc.additionalSafeAreaInsets = .zero
            }
        }

        self.view.layoutIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if KZLibrary.libraries.isEmpty {
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
        vc.view.layer.shadowColor = RGB(0).cgColor
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
        }, completion: nil)
    }

    func hideMenu() {
        UIView.animate(withDuration: Constants.UI.Animation.menuSlide, delay: 0.0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            self.xOffsetConstraint?.constant = -Constants.UI.Navigation.menuWidth
            self.view.layoutIfNeeded()
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

        navigationController.view.isHidden = false
        prevNavigationController?.view.isHidden = true
        view.bringSubviewToFront(navigationController.view)
        view.bringSubviewToFront(playerViewController.view)
        navigationController.didMove(toParent: self)

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
