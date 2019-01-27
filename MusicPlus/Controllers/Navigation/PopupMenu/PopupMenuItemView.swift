//
//  PopupMenuItemView.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/15.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation

struct PopupMenuAction: OptionSet {
    let rawValue: Int

    static let play = PopupMenuAction(rawValue: 1)
    static let addUpNext = PopupMenuAction(rawValue: 2)
    static let goToArtist = PopupMenuAction(rawValue: 4)
    static let goToAlbum = PopupMenuAction(rawValue: 8)
}

class PopupMenuItemView: UIView {

    let stackView = UIStackView()

    init(item: Any, exclude exclusionSet: PopupMenuAction = [], handler: @escaping (PopupMenuAction) -> Void) {
        super.init(frame: .zero)

        setup()
        if !exclusionSet.contains(.play) {
            if let item = item as? KZPlayerItemBase {
                stackView.addArrangedSubview(PopupItemHeaderView(item: item) {
                    handler(.play)
                })
            } else if let item = item as? KZPlayerArtist {
                stackView.addArrangedSubview(PopupItemHeaderView(item: item) {
                    handler(.play)
                })
            } else if let item = item as? KZPlayerAlbum {
                stackView.addArrangedSubview(PopupItemHeaderView(item: item) {
                    handler(.play)
                })
            }
        }
        if !exclusionSet.contains(.addUpNext) {
            stackView.addArrangedSubview(PopupItemActionView(title: NSLocalizedString("Add Up Next", comment: ""), image: #imageLiteral(resourceName: "sidebarPartyPlaylistIcon")) {
                handler(.addUpNext)
            })
        }
        if !exclusionSet.contains(.goToArtist) {
            stackView.addArrangedSubview(PopupItemActionView(title: NSLocalizedString("Go To Artist", comment: ""), image: #imageLiteral(resourceName: "sidebarArtistIcon")) {
                handler(.goToArtist)
            })
        }
        if !exclusionSet.contains(.goToAlbum) {
            stackView.addArrangedSubview(PopupItemActionView(title: NSLocalizedString("Go To Album", comment: ""), image: #imageLiteral(resourceName: "sidebarAlbumIcon")) {
                handler(.goToAlbum)
            })
        }
    }

    func setup() {
        backgroundColor = .init(white: 1.0, alpha: 0.7)

        stackView.axis = .vertical
        stackView.spacing = 2.0
        addSubview(stackView)

        stackView.autoPinEdgesToSuperviewEdges()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        stackView.arrangedSubviews.forEach { $0.touchesBegan(touches, with: event) }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        stackView.arrangedSubviews.forEach { $0.touchesMoved(touches, with: event) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        stackView.arrangedSubviews.forEach { $0.touchesEnded(touches, with: event) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
