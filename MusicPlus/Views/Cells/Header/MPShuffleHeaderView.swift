// 
//  MPShuffleHeaderView.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/16/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit

class MPShuffleHeaderView: UIButton {

    let label = UILabel()
    let shuffleImage = UIImageView(image: #imageLiteral(resourceName: "shuffleBT"))

    override init(frame: CGRect) {
        var frame = frame
        frame.size.width = Constants.UI.Screen.width
        frame.size.height = 43
        super.init(frame: frame)

        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setupView() {

        label.textColor = RGB(255)
        label.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        label.text = "Shuffle All"
        addSubview(label)

        shuffleImage.alpha = 0.4
        addSubview(shuffleImage)

        setupConstraints()
    }

    func setupConstraints() {
        label.autoPinEdge(toSuperviewEdge: .left, withInset: 17)
        label.autoAlignAxis(toSuperviewAxis: .horizontal)

        shuffleImage.autoPinEdge(toSuperviewEdge: .right, withInset: 17)
        shuffleImage.autoAlignAxis(toSuperviewAxis: .horizontal)
    }

}
