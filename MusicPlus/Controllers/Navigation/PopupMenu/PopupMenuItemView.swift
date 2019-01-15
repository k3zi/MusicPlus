//
//  PopupMenuItemView.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/15.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation

enum PopupMenuAction {
    case play
    case addUpNext
}

class PopupMenuItemView: UIView {

    let stackView = UIStackView()

    init(item: KZPlayerItemBase, handler: @escaping (PopupMenuAction) -> Void) {
        super.init(frame: .zero)

        setup()
        stackView.addArrangedSubview(PopupItemHeaderView(item: item) {
            handler(.play)
        })
        stackView.addArrangedSubview(PopupItemActionView(title: NSLocalizedString("Add Up Next", comment: ""), image: #imageLiteral(resourceName: "sidebarPartyPlaylistIcon")) {
            handler(.addUpNext)
        })
    }

    init(item: KZPlayerAlbum, handler: @escaping (PopupMenuAction) -> Void) {
        super.init(frame: .zero)

        setup()
        stackView.addArrangedSubview(PopupItemHeaderView(item: item) {
            handler(.play)
        })
        stackView.addArrangedSubview(PopupItemActionView(title: NSLocalizedString("Add Up Next", comment: ""), image: #imageLiteral(resourceName: "sidebarPartyPlaylistIcon")) {
            handler(.addUpNext)
        })
    }

    init(item: KZPlayerArtist, handler: @escaping (PopupMenuAction) -> Void) {
        super.init(frame: .zero)

        setup()
        stackView.addArrangedSubview(PopupItemHeaderView(item: item) {
            handler(.play)
        })
        stackView.addArrangedSubview(PopupItemActionView(title: NSLocalizedString("Add Up Next", comment: ""), image: #imageLiteral(resourceName: "sidebarPartyPlaylistIcon")) {
            handler(.addUpNext)
        })
    }

    func setup() {
        backgroundColor = .init(white: 1.0, alpha: 0.6)

        stackView.axis = .vertical
        stackView.spacing = 1.0
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

    override var canBecomeFirstResponder: Bool {
        return true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
