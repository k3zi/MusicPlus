//
//  PopupItemActionView.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/14.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class PopupItemActionView: PopupItemView {

    let label = UILabel()

    let imageView = UIImageView()

    init(title: String, image: UIImage, didSelect: @escaping () -> Void) {
        super.init(frame: .zero)
        self.didSelect = didSelect
        label.text = title
        imageView.image = image
        setupView()

        NotificationCenter.default.addObserver(self, selector: #selector(updateTint), name: Constants.Notification.tintColorDidChange, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setupView() {
        backgroundColor = Constants.UI.Color.popupMenuItem
        isUserInteractionEnabled = true

        label.font = .systemFont(ofSize: 20, weight: .regular)
        label.textColor = AppDelegate.del().session.tintColor
        addSubview(label)

        imageView.tintColor = AppDelegate.del().session.tintColor
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)

        setupConstraints()
    }

    func setupConstraints() {
        label.autoPinEdgesToSuperviewEdges(with: .init(top: 15, left: 15, bottom: 15, right: 0), excludingEdge: .right)

        imageView.autoPinEdgesToSuperviewEdges(with: .init(top: 15, left: 0, bottom: 15, right: 15), excludingEdge: .left)
        imageView.autoPinEdge(.left, to: .right, of: label, withOffset: 15, relation: .greaterThanOrEqual)
        imageView.autoMatch(.width, to: .height, of: imageView)
    }

    @objc func updateTint() {
        let tintColor = AppDelegate.del().session.tintColor
        label.textColor = tintColor
        imageView.tintColor = tintColor
    }

}
