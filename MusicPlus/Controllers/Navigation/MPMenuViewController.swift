// 
//  MPMenuViewController.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/12/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

import UIKit

class MPMenuViewController: KZViewController {

    var hasLoaded = false

    let menuView = UIView()
    let backgroundImageView = UIImageView(image: #imageLiteral(resourceName: "defaultBackground"))
    let darkOverlayView = GradientView()

    let shadowView = GradientView()
    let logoImageView = UIImageView(image: #imageLiteral(resourceName: "menuLogo"))
    lazy var selectLibraryButton: ExtendedButton = {
        let button = ExtendedButton()
        button.setTitle("Library", for: .normal)
        button.setImage(#imageLiteral(resourceName: "disclosureArrow"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)

        button.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        button.imageEdgeInsets = .init(top: 0, left: -30, bottom: 0, right: 0)
        button.titleEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: -30)
        button.contentEdgeInsets = .init(top: -30, left: 0, bottom: -30, right: 0)
        button.sizeToFit()

        button.setBackgroundColor(UIColor.white.withAlphaComponent(0.025), forState: .normal)
        button.adjustsImageWhenHighlighted = false
        button.showsTouchWhenHighlighted = false

        button.addTarget(self, action: #selector(toggleLibrarySelection), for: .touchUpInside)
        return button
    }()

    lazy var menuTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cellType: MPMenuItemTableViewCell.self)
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.allowsMultipleSelection = true
        tableView.delaysContentTouches = false
        return tableView
    }()

    lazy var libraryTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cellType: MPLibraryCell.self)
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.allowsMultipleSelection = true
        tableView.delaysContentTouches = false
        return tableView
    }()

    let librarySelectionView = UIView()
    var showLibrarySelection = false

    var dynamicConstraints = [NSLayoutConstraint]()

    var menuItems = [Any]()

    override func viewDidLoad() {
        super.viewDidLoad()

        menuTableView.contentInsetAdjustmentBehavior = .always
        libraryTableView.contentInsetAdjustmentBehavior = .always
        view.translatesAutoresizingMaskIntoConstraints = false
        fetchAUtomatically = false

        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        view.addSubview(backgroundImageView)

        darkOverlayView.colors = [UIColor.black.withAlphaComponent(0.6).cgColor, UIColor.black.withAlphaComponent(0.8).cgColor]
        view.addSubview(darkOverlayView)

        view.addSubview(menuView)

        logoImageView.contentMode = .scaleAspectFit
        menuView.addSubview(logoImageView)

        menuTableView.tableHeaderView = selectLibraryButton
        menuView.addSubview(menuTableView)

        librarySelectionView.addSubview(libraryTableView)

        shadowView.backgroundColor = UIColor.clear
        shadowView.startPoint = CGPoint(x: 0.5, y: 0.0)
        shadowView.endPoint = CGPoint(x: 0.5, y: 1.0)
        shadowView.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        shadowView.alpha = 0.0
        menuView.addSubview(shadowView)

        view.addSubview(librarySelectionView)
        librarySelectionView.backgroundColor = UIColor.white.withAlphaComponent(0.05)

        menuItems.removeAll()
        menuItems.append(MPMenuItem(name: "SONGS", imageName: "sidebarSongIcon", controller: SongsViewController.shared, selected: true))
        menuItems.append(MPMenuItem(name: "ALBUMS", imageName: "sidebarAlbumIcon", controller: AlbumsViewController.shared))
        menuItems.append(MPMenuItem(name: "ARTISTS", imageName: "sidebarArtistIcon", controller: ArtistsViewController.shared))
        menuItems.append(MPMenuItem(name: "SEARCH", imageName: "sidebarSearchIcon", controller: SearchViewController.shared))
        // menuItems.append(MPMenuItem(name: "PARTY PLAYLIST", imageName: "sidebarPartyPlaylistIcon", controller: SongsViewController.shared))
        // menuItems.append(MPMenuItem(name: "SLEEP TIMER", imageName: "sidebarSleepTimerIcon", controller: SongsViewController.shared))
        // menuItems.append(MPMenuItem(name: "COLOR", imageName: "sidebarColorIcon", controller: SongsViewController.shared))
        // menuItems.append(MPMenuItem(name: "PLEX", imageName: "sidebarPlexIcon", controller: SongsViewController.shared))
        menuItems.append(MPMenuItem(name: "SETTINGS", imageName: "sidebarSettingsIcon", controller: SettingsViewController.shared))
        menuTableView.reloadData()

        NotificationCenter.default.addObserver(forName: .libraryDidChange, object: nil, queue: nil) { [weak self] _ in
            guard let self = self else {
                return
            }

            self.libraryTableView.reloadData()
        }.dispose(with: self)
    }

    override func setupConstraints() {
        super.setupConstraints()

        backgroundImageView.autoPinEdgesToSuperviewEdges()
        darkOverlayView.autoPinEdgesToSuperviewEdges()

        menuView.autoSetDimension(.width, toSize: Constants.UI.Navigation.menuWidth)
        menuView.autoPin(toTopLayoutGuideOf: self, withInset: 8)
        menuView.autoPinEdge(toSuperviewEdge: .left)
        menuView.autoPin(toBottomLayoutGuideOf: self, withInset: 0)

        librarySelectionView.autoPin(toTopLayoutGuideOf: self, withInset: 8)
        librarySelectionView.autoPinEdge(.left, to: .right, of: menuView)
        librarySelectionView.autoPin(toBottomLayoutGuideOf: self, withInset: 0)
        librarySelectionView.autoPinEdge(toSuperviewEdge: .right)
        dynamicConstraints.append(librarySelectionView.autoSetDimension(.width, toSize: 0))

        libraryTableView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .right)
        libraryTableView.autoPinEdge(.right, to: .right, of: view.superview!)

        logoImageView.autoPinEdge(toSuperviewEdge: .top)
        logoImageView.autoMatch(.width, to: .width, of: menuView, withMultiplier: 0.5)
        logoImageView.autoAlignAxis(.vertical, toSameAxisOf: menuView, withOffset: -2)

        menuTableView.autoPinEdge(.top, to: .bottom, of: logoImageView, withOffset: 12)
        menuTableView.autoPinEdge(toSuperviewEdge: .left)
        menuTableView.autoPinEdge(toSuperviewEdge: .right)
        menuTableView.autoPinEdge(toSuperviewEdge: .bottom)

        shadowView.autoPinEdge(.top, to: .top, of: menuTableView)
        shadowView.autoPinEdge(toSuperviewEdge: .left)
        shadowView.autoPinEdge(toSuperviewEdge: .right)
        shadowView.autoSetDimension(.height, toSize: 21)
    }

    func expandLibrarySelection() {
        guard !showLibrarySelection else {
            return
        }

        showLibrarySelection = true
        UIView.transition(with: selectLibraryButton, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.selectLibraryButton.setBackgroundColor(UIColor.white.withAlphaComponent(0.05), forState: .normal)
        }, completion: nil)
        UIView.animate(withDuration: 0.5) {
            self.dynamicConstraints.forEach({ $0.autoRemove() })
            self.dynamicConstraints.removeAll()
            if let superview = self.view.superview {
                self.dynamicConstraints.append(self.librarySelectionView.autoMatch(.width, to: .width, of: superview, withOffset: -Constants.UI.Navigation.menuWidth))
            }
            self.view.superview?.layoutSubviews()
            self.view.layoutSubviews()
        }
    }

    func collapseLibrarySelection() {
        guard showLibrarySelection else {
            return
        }

        showLibrarySelection = false
        UIView.transition(with: selectLibraryButton, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.selectLibraryButton.setBackgroundColor(UIColor.white.withAlphaComponent(0.025), forState: .normal)
        }, completion: nil)
        UIView.animate(withDuration: 0.5) {
            self.dynamicConstraints.forEach({ $0.autoRemove() })
            self.dynamicConstraints.removeAll()
            self.dynamicConstraints.append(self.librarySelectionView.autoSetDimension(.width, toSize: 0))
            self.view.superview?.layoutSubviews()
            self.view.layoutSubviews()
        }
    }

    @objc func toggleLibrarySelection() {
        if showLibrarySelection {
            collapseLibrarySelection()
        } else {
            expandLibrarySelection()
        }
    }

    @objc func addAlibrary() {
        self.parent?.present(CreateLibraryViewController(), animated: true, completion: nil)
    }

    // MARK: - TableView DataSource / Delegate

    override func tableViewCellData(_ tableView: UITableView, section: Int) -> [Any] {
        if tableView == libraryTableView {
            return KZRealmLibrary.libraries.toArray()
        }

        return menuItems
    }

    override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath?) -> KZTableViewCell.Type {
        if tableView == libraryTableView {
            return MPLibraryCell.self
        }

        return MPMenuItemTableViewCell.self
    }

    override func tableViewShowsSectionHeader(_ tableView: UITableView) -> Bool {
       return tableView == libraryTableView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == libraryTableView {
            return 44
        }

        return super.tableView(tableView, heightForHeaderInSection: section)
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if tableView == libraryTableView {
            return 44
        }

        return super.tableView(tableView, heightForFooterInSection: section)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == libraryTableView {
            let button = UIButton()
            button.setTitle("Library Selection:", for: .normal)
            return button
        }

        return super.tableView(tableView, viewForHeaderInSection: section)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if tableView == libraryTableView {
            let button = UIButton()
            button.setTitle("+ Create a Library", for: .normal)
            button.backgroundColor = UIColor.init(white: 1.0, alpha: 0.1)
            button.addTarget(self, action: #selector(addAlibrary), for: .touchUpInside)
            return button
        }

        return nil
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let percent = min(scrollView.contentOffset.y / 300.0, 0.3)
        shadowView.alpha = percent
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == libraryTableView {
            guard let library = self.tableViewCellData(tableView, section: indexPath.section)[indexPath.row] as? KZRealmLibrary else {
                return
            }

            collapseLibrarySelection()

            KZPlayer.sharedInstance.currentLibrary = library
        } else if tableView == menuTableView {
            tableView.deselectRow(at: indexPath, animated: false)
            guard let allItems = tableViewCellData(tableView, section: indexPath.section) as? [MPMenuItem] else {
                return
            }

            for i in 0..<allItems.count {
                allItems[i].selected = i == indexPath.row
            }

            for cell in tableView.visibleCells {
                (cell as? MPMenuItemTableViewCell)?.fillInCellData(false)
            }

            let item = allItems[indexPath.row]

            collapseLibrarySelection()

            if item.shouldPresent {
                MPContainerViewController.sharedInstance.present(item.controller, animated: true, completion: nil)
            } else {
                MPContainerViewController.sharedInstance.switchToNavigationController(item.controller)
            }
        }
    }

    func tableView(_ tableView: UITableView, willDeselectRowAtIndexPath indexPath: IndexPath) -> IndexPath? {
        self.tableView(tableView, didSelectRowAt: indexPath)
        return nil
    }

}
