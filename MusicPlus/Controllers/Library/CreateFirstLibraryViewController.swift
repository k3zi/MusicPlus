//
//  CreateLibraryViewController.swift
//  Music+
//
//  Created by kezi on 2019/01/05.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation
import MediaPlayer
import PromiseKit

class CreateLibraryViewController: KZViewController, UITextFieldDelegate {

    let welcomeLabel = UILabel()
    let nameTextField = UITextField()
    let typeLabel = UILabel()
    var typeSelectedIndexPath: IndexPath?
    let tableView = KZIntrinsicTableView()
    let infoLabel = UILabel()
    let nextButton = UIButton()

    var libraryTypes = [Any]()

    init() {
        super.init(nibName: nil, bundle: nil)

        libraryTypes.append(MPLibraryItem(name: "Local (Empty)", icon: #imageLiteral(resourceName: "serverIItunesIcon")))
        libraryTypes.append(MPLibraryItem(name: "Local (Import All Songs)", icon: #imageLiteral(resourceName: "serverIItunesIcon")))
        libraryTypes.append(MPLibraryItem(name: "Plex (Read Only)", icon: #imageLiteral(resourceName: "sidebarPlexIcon")))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        welcomeLabel.font = .boldSystemFont(ofSize: 40)
        welcomeLabel.numberOfLines = 0
        view.addSubview(welcomeLabel)

        nameTextField.backgroundColor = RGB(72)
        nameTextField.layer.cornerRadius = 10
        nameTextField.layer.masksToBounds = true
        nameTextField.font = .systemFont(ofSize: 25)
        nameTextField.textColor = .white
        nameTextField.textAlignment = .left
        nameTextField.delegate = self
        nameTextField.attributedPlaceholder = NSAttributedString(string: "Enter a Name", attributes: [NSAttributedString.Key.foregroundColor: RGB(172)])
        nameTextField.layer.sublayerTransform = CATransform3DMakeTranslation(12, 0, 0)
        view.addSubview(nameTextField)

        typeLabel.text = "Type of Library:"
        typeLabel.font = .systemFont(ofSize: 25)
        view.addSubview(typeLabel)

        infoLabel.text = ""
        infoLabel.font = .systemFont(ofSize: 20)
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        infoLabel.isUserInteractionEnabled = true
        infoLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openRequestLink)))
        view.addSubview(infoLabel)

        nextButton.setTitle("Create", for: .normal)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.setTitleColor(.lightGray, for: .disabled)
        nextButton.setBackgroundColor(.nativeBlue, forState: .normal)
        nextButton.setBackgroundColor(RGB(250), forState: .disabled)
        nextButton.setBackgroundColor(UIColor.nativeBlue.withAlphaComponent(0.1), forState: .highlighted)
        nextButton.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
        nextButton.layer.cornerRadius = 10
        nextButton.layer.masksToBounds = true
        view.addSubview(nextButton)

        welcomeLabel.text = "Add A Library"
        if KZRealmLibrary.libraries.isEmpty {
            welcomeLabel.textAlignment = .center

            typeLabel.textAlignment = .center
        } else {
            welcomeLabel.textAlignment = .left

            typeLabel.textAlignment = .left
        }

        tableView.register(cellType: MPLibraryCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = RGB(72)
        tableView.layer.cornerRadius = 10
        tableView.layer.masksToBounds = true
        view.addSubview(tableView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        welcomeLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 12)
        welcomeLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 12)
        welcomeLabel.autoPin(toTopLayoutGuideOf: self, withInset: 24)

        nameTextField.autoPinEdge(.top, to: .bottom, of: welcomeLabel, withOffset: 24)
        nameTextField.autoPinEdge(toSuperviewEdge: .left, withInset: 12)
        nameTextField.autoPinEdge(toSuperviewEdge: .right, withInset: 12)
        nameTextField.autoSetDimension(.height, toSize: 44)

        typeLabel.autoPinEdge(.top, to: .bottom, of: nameTextField, withOffset: 24)
        typeLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 12)
        typeLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 12)

        tableView.autoPinEdge(.top, to: .bottom, of: typeLabel, withOffset: 12)
        tableView.autoPinEdge(toSuperviewEdge: .left, withInset: 12)
        tableView.autoPinEdge(toSuperviewEdge: .right, withInset: 12)

        infoLabel.autoPinEdge(.top, to: .bottom, of: tableView, withOffset: 12)
        infoLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 12)
        infoLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 12)

        nextButton.autoPinEdge(.top, to: .bottom, of: infoLabel, withOffset: 12)
        nextButton.autoPinEdge(toSuperviewEdge: .left, withInset: 12)
        nextButton.autoPinEdge(toSuperviewEdge: .right, withInset: 12)
        nextButton.autoSetDimension(.height, toSize: 44)
        nextButton.autoPin(toBottomLayoutGuideOf: self, withInset: 24, relation: .greaterThanOrEqual)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        nameTextField.resignFirstResponder()
    }

    @objc func openRequestLink() {
        UIApplication.shared.open(URL.init(string: KZPlex.Path.linkAccount)!, options: [:], completionHandler: nil)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    override func tableViewCellData(_ tableView: UITableView, section: Int) -> [Any] {
        return libraryTypes
    }

    override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath?) -> KZTableViewCell.Type {
        return MPLibraryCell.self
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.accessoryType = typeSelectedIndexPath == indexPath ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard nextButton.isEnabled else {
            return
        }

        typeSelectedIndexPath = indexPath
        tableView.reloadData()
    }

    @objc func didTapNext() {
        guard let name = nameTextField.text, name.isNotEmpty else {
            let alertController = UIAlertController(title: "Add A Library", message: "Please give a name to the library you wish to add.", preferredStyle: .alert)
            alertController.addAction(.init(title: Strings.Buttons.ok, style: .default))
            return present(alertController, animated: true, completion: nil)
        }

        guard let typeSelectedIndexPath = typeSelectedIndexPath else {
            let alertController = UIAlertController(title: "Add A Library", message: "Please select the type of library you wish to add.", preferredStyle: .alert)
            alertController.addAction(.init(title: Strings.Buttons.ok, style: .default))
            return present(alertController, animated: true, completion: nil)
        }

        nameTextField.isEnabled = false
        nextButton.isEnabled = false

        switch typeSelectedIndexPath.row {
        case 0:
            let library = KZRealmLibrary(name: name, type: .localEmpty)
            let realm = Realm.main
            try! realm.write {
                realm.add(library)
            }
            KZPlayer.sharedInstance.currentLibrary = library
            presentingViewController?.dismiss(animated: true, completion: nil)
        case 1:
            let library = KZRealmLibrary(name: name, type: .local)
            let realm = Realm.main
            try! realm.write {
                realm.add(library)
            }
            nextButton.setTitle("Importing Songs...", for: .normal)
            let safeLibrary = library.safeReference
            MPMediaLibrary.requestAuthorization { _ in
                safeLibrary.resolve()?.addAllItems { status, complete in
                    DispatchQueue.main.async {
                        self.nextButton.setTitle(status, for: .normal)
                        if complete {
                            KZPlayer.sharedInstance.currentLibrary = library
                            self.presentingViewController?.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
        case 2:
            let plex = KZPlex()
            plex.signIn(progressCallback: { status in
                DispatchQueue.main.async {
                    self.nextButton.setTitle("Requesting Access...", for: .normal)
                    self.infoLabel.attributedText = status
                }
            }, completionCallBack: { request in
                DispatchQueue.main.async {
                    self.nextButton.setTitle("Loading Libraries...", for: .normal)
                }
                plex.authToken = request.authToken
                _ = plex.resources().then { response -> Promise<[LibrarySectionsGETResponse?]> in
                    let arrayOfPromises = response.devices.flatMap({ $0.connections }).map({ $0.sections() })
                    return when(fulfilled: arrayOfPromises)
                }.done { response in
                    let servers = response.compactMap { $0 }
                    var libraries: [Directory] = servers.flatMap { $0.directories }
                    libraries = libraries.uniqueElements.filter { $0.type == .artist }
                    DispatchQueue.main.async {
                        let librarySelectionAlertController = UIAlertController(title: "Plex Library", message: "Please select a plex directory.", preferredStyle: .actionSheet)
                        libraries.forEach { library in
                            let action = UIAlertAction(title: library.title, style: .default) { action in
                                guard let index = librarySelectionAlertController.actions.firstIndex(of: action) else {
                                    return
                                }

                                let directory = libraries[index]
                                let plexLibrary = KZRealmLibrary(name: name, type: .plex, plexLibraryConfig: .init(authToken: directory.device.accessToken, clientIdentifier: directory.device.clientIdentifier, dircetoryUUID: directory.uuid, connectionURI: directory.connection.uri))
                                let realm = Realm.main
                                try! realm.write {
                                    realm.add(plexLibrary)
                                }
                                KZPlayer.sharedInstance.currentLibrary = plexLibrary
                                self.presentingViewController?.dismiss(animated: true, completion: nil)
                            }
                            librarySelectionAlertController.addAction(action)
                        }
                        if let popoverController = librarySelectionAlertController.popoverPresentationController {
                            popoverController.sourceView = self.nextButton
                            popoverController.sourceRect = CGRect(x: self.nextButton.bounds.midX, y: self.nextButton.bounds.midY, width: 0, height: 0)
                            popoverController.permittedArrowDirections = []
                        }
                        self.present(librarySelectionAlertController, animated: true, completion: nil)
                    }
                }
            })
        default: break
        }
    }

}
