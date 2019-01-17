// 
//  MPShuffleHeaderView.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/16/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit

class MPShuffleHeaderView: UIControl {

    let label = UILabel()
    let shuffleImage = UIImageView(image: #imageLiteral(resourceName: "shuffleBT"))

    override init(frame: CGRect) {
        var frame = frame
        frame.size.width = Constants.UI.Screen.width
        frame.size.height = 46
        super.init(frame: frame)
        setupView()

        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleGesture))
        gesture.minimumPressDuration = 0.0
        gesture.allowableMovement = 9999
        self.addGestureRecognizer(gesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func handleGesture(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            let touchedPoint = gesture.location(in: self)
            setHighlighted(bounds.contains(touchedPoint), animated: true)
        } else if gesture.state == .ended {
            setHighlighted(false, animated: true)
            let touchedPoint = gesture.location(in: self)
            if bounds.contains(touchedPoint) {
                sendActions(for: .touchUpInside)
            }
        }
    }

    func setupView() {
        label.textColor = .white
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

    func setHighlighted(_ highlighted: Bool, animated: Bool) {
        func runAnimations() {
            backgroundColor = highlighted ? RGB(255, a: 0.2) : UIColor.clear
        }

        if animated {
            UIView.animate(withDuration: Constants.UI.Animation.cellHighlight, animations: runAnimations)
        } else {
            runAnimations()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}
