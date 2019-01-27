// 
//  MPOptionsButton.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/13/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

import UIKit

protocol MPOptionsButtonDelegate {
    func optionsButtonWillExpand(_ button: MPOptionsButton)
    func optionsButtonDidClick(_ button: MPOptionsButton, index: Int)
}

class MPOptionsButton: UIView {

    let toggleButton = ExtendedButton()
    var buttonHolder = UIView()
    var buttons = [UIButton]()
    var delegate: MPOptionsButtonDelegate?

    var closedConstraints = [NSLayoutConstraint]()
    var expandedConstraints = [NSLayoutConstraint]()

    init(buttons: [(icon: String, name: String)]) {
        super.init(frame: CGRect.zero)
        clipsToBounds = false
        translatesAutoresizingMaskIntoConstraints = false

        toggleButton.tintColor = .white
        toggleButton.setImage(#imageLiteral(resourceName: "optionsUnfilled"), for: .normal)
        toggleButton.setImage(#imageLiteral(resourceName: "optionsFilled").withRenderingMode(.alwaysTemplate), for: .selected)
        toggleButton.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        addSubview(toggleButton)

        setupConstraints()

        buttonHolder.alpha = 0.0
        addButtons(buttons)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extendedArea = self.bounds.insetBy(dx: -6, dy: -20)
        return extendedArea.contains(point)
    }

    func setupConstraints() {
        NSLayoutConstraint.autoSetPriority(UILayoutPriority.required) {
            self.toggleButton.autoPinEdge(toSuperviewEdge: .top, withInset: 11)
            self.toggleButton.autoPinEdge(toSuperviewEdge: .right, withInset: 11)

            if let image = self.toggleButton.currentImage {
                self.toggleButton.autoSetDimensions(to: image.size)
            }
        }

        close()
    }

    func addButtons(_ items: [(icon: String, name: String)]) {
        for i in 0 ..< items.count {
            let item = items[i]
            let button = UIButton()
            if item.icon.count > 0 {
                button.setImage(UIImage(named: item.icon), for: .normal)
            }
            button.setBackgroundColor(.black, forState: .normal)
            button.setBackgroundColor(.white, forState: .selected)
            button.setTitleColor(.white, for: .normal)
            button.setTitleColor(.black, for: .selected)
            button.setTitle(item.name, for: .normal)
            button.addTarget(self, action: #selector(didClickButton), for: .touchUpInside)
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
            button.tag = i
            buttonHolder.addSubview(button)
            buttons.append(button)

            button.autoPinEdge(toSuperviewEdge: .left)
            button.autoPinEdge(toSuperviewEdge: .right)

            if i == 0 {
                button.autoPinEdge(toSuperviewEdge: .top)
            } else {
                button.autoPinEdge(.top, to: .bottom, of: buttons[i-1])
            }

            if i > 0 {
                let line = UIView.lineWithBGColor(RGB(85))
                button.addSubview(line)
                line.autoPinEdge(toSuperviewEdge: .left)
                line.autoPinEdge(toSuperviewEdge: .right)
                line.autoPinEdge(toSuperviewEdge: .top)
            }

            if i == (items.count - 1) {
                button.autoPinEdge(toSuperviewEdge: .bottom)
            }
        }
    }

    @objc func didClickButton(_ button: UIButton) {
        button.isSelected = true
        delegate?.optionsButtonDidClick(self, index: button.tag)
        delay(0.7) {
            button.isSelected = false
        }
    }

    @objc func toggle() {
        if toggleButton.isSelected {
            UIView.animate(withDuration: 0.4, animations: {
                self.buttonHolder.alpha = 0.0
                }, completion: { (_) in
                    UIView.animate(withDuration: 0.2, animations: {
                        self.close()
                    })
            })
        } else {
            self.delegate?.optionsButtonWillExpand(self)
            UIView.animate(withDuration: 0.2, animations: {
                self.expand()
                }, completion: { (_) in
                    UIView.animate(withDuration: 0.4, animations: {
                        self.buttonHolder.alpha = 1.0
                    })
            })
        }
    }

    func expand() {
        NotificationCenter.default.post(name: .hidePopup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toggle), name: .hidePopup, object: nil)
        toggleButton.isSelected = true

        self.backgroundColor = .black
        self.superview?.addSubview(buttonHolder)
        expandedConstraints.append(contentsOf: [buttonHolder.autoPinEdge(.top, to: .bottom, of: self), buttonHolder.autoPinEdge(.left, to: .left, of: self), buttonHolder.autoPinEdge(.right, to: .right, of: self)])
        self.layoutIfNeeded()
    }

    func close() {
        NotificationCenter.default.removeObserver(self)
        toggleButton.isSelected = false

        backgroundColor = UIColor.clear
        expandedConstraints.forEach({ $0.autoRemove() })
        closedConstraints.append(contentsOf: [toggleButton.autoPinEdge(toSuperviewEdge: .left, withInset: 12, relation: .greaterThanOrEqual), toggleButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 12, relation: .greaterThanOrEqual)])
        buttonHolder.removeFromSuperview()
        self.layoutIfNeeded()
    }
}
