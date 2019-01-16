//
//  PopupItemHeaderView.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/14.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

class PopupItemHeaderView: PopupItemView {

    let stackView = UIStackView(frame: .zero)
    let songLabel = UILabel()
    let artistLabel = UILabel()
    let albumLabel = UILabel()

    let albumImageView = UIImageView()

    init(item: KZPlayerItemBase, didSelect: @escaping () -> Void) {
        super.init(frame: .zero)
        self.didSelect = didSelect

        item.fetchArtwork { artwork in
            self.albumImageView.image = artwork.image(at: CGSize(width: 115, height: 115))
        }

        songLabel.text = item.title
        artistLabel.text = item.artist?.name
        albumLabel.text = item.album?.name

        setupView()
    }

    init(item: KZPlayerAlbum, didSelect: @escaping () -> Void) {
        super.init(frame: .zero)
        self.didSelect = didSelect

        if let song = item.songs.first {
            song.fetchArtwork { artwork in
                self.albumImageView.image = artwork.image(at: CGSize(width: 115, height: 115))
            }
        }

        songLabel.text = item.name
        artistLabel.text = item.artist?.name

        setupView()
    }

    init(item: KZPlayerArtist, didSelect: @escaping () -> Void) {
        super.init(frame: .zero)
        self.didSelect = didSelect

        if let song = item.songs.first {
            song.fetchArtwork { artwork in
                self.albumImageView.image = artwork.image(at: CGSize(width: 115, height: 115))
            }
        }

        songLabel.text = item.name

        setupView()
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

        stackView.axis = .vertical
        stackView.spacing = 2
        addSubview(stackView)

        albumImageView.clipsToBounds = true
        albumImageView.contentMode = .scaleAspectFill
        albumImageView.backgroundColor = Constants.UI.Color.gray
        addSubview(albumImageView)

        songLabel.textColor = .black
        songLabel.font = .systemFont(ofSize: 18, weight: UIFont.Weight.medium)
        stackView.addArrangedSubview(songLabel)

        artistLabel.textColor = .black
        artistLabel.font = .systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        stackView.addArrangedSubview(artistLabel)

        albumLabel.textColor = .init(white: 0, alpha: 0.7)
        albumLabel.font = .systemFont(ofSize: 15, weight: UIFont.Weight.regular)
        stackView.addArrangedSubview(albumLabel)

        setupConstraints()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTint), name: Constants.Notification.tintColorDidChange, object: nil)
    }

    func setupConstraints() {
        albumImageView.autoPinEdge(toSuperviewEdge: .top, withInset: 15)
        albumImageView.autoPinEdge(toSuperviewEdge: .left, withInset: 15)
        albumImageView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 15)
        albumImageView.autoSetDimensions(to: CGSize(width: 70, height: 70))

        stackView.autoAlignAxis(toSuperviewAxis: .horizontal)
        stackView.autoPinEdge(.left, to: .right, of: albumImageView, withOffset: 15)
        stackView.autoPinEdge(toSuperviewEdge: .right, withInset: 14)
        stackView.autoPinEdge(toSuperviewEdge: .top, withInset: 15, relation: .greaterThanOrEqual)
        stackView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 15, relation: .greaterThanOrEqual)
    }

    @objc func updateTint() {
        // heartButton.tintColor = AppDelegate.del().session.tintColor
    }

}