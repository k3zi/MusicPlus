// 
//  SettingsViewController.swift
//  Music+
// 
//  Created by Kesi Maduka on 6/15/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit
import Flix
import RxSwift

class SettingsViewController: MPViewController {

    static let shared = SettingsViewController()
    let disposeBag = DisposeBag()

    let tableView = UITableView()
    let shadowView = UIView()
    let shadowLayer = CAGradientLayer()
    var shadowTopConstraint: NSLayoutConstraint?
    var topLayoutGuideConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        view.addSubview(tableView)
        view.addSubview(shadowView)
        super.viewDidLoad()

        shadowView.backgroundColor = .clear
        shadowLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        shadowLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        shadowLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        shadowView.layer.insertSublayer(shadowLayer, at: 0)
        shadowView.alpha = 0.0
        view.addSubview(shadowView)

        title = "Settings"
        setupMenuToggle()

        // MARK: - Crossfade
        let crossfadeHeader = TitleTableViewSectionProvider(name: "CROSSFADE")

        let crossfadeSetting = Constants.Settings.Info.crossfade
        let crossfadeProvider = SwitchTableViewCellProvider(title: crossfadeSetting.title, subTitle: crossfadeSetting.description, isOn: false)
        UserDefaults.standard.bidirectionalBind(control: crossfadeProvider.uiSwitch.rx.isOn, keyPath: crossfadeSetting.accessor, defaultValue: false).disposed(by: disposeBag)

        let crossfadAtSecondseSetting = Constants.Settings.Info.crossfadeAtSeconds
        let crossfadeAtProvider = DescriptionTableViewCellProvider(title: crossfadAtSecondseSetting.title, subTitle: crossfadAtSecondseSetting.description, icon: nil) {
            let vc = UIAlertController(title: crossfadAtSecondseSetting.title, message: crossfadAtSecondseSetting.description, preferredStyle: .actionSheet)
            let currentValue = max(UserDefaults.standard.double(forKey: crossfadAtSecondseSetting.accessor), Constants.Settings.Options.crossfadeAtSeconds[0])
            Constants.Settings.Options.crossfadeAtSeconds.forEach { option in
                vc.addAction(.init(title: "\(currentValue == option ? "✔︎  " : "")\(Int(option)) seconds", style: .default) { _ in
                    UserDefaults.standard.set(option, forKey: crossfadAtSecondseSetting.accessor)
                })
            }
            self.presentAlert(vc, animated: true, completion: nil)
        }

        let crossfadDurationSecondseSetting = Constants.Settings.Info.crossfadeDurationSeconds
        let crossfadeDurationProvider = DescriptionTableViewCellProvider(title: crossfadDurationSecondseSetting.title, subTitle: crossfadDurationSecondseSetting.description, icon: nil) {
            let vc = UIAlertController(title: crossfadDurationSecondseSetting.title, message: crossfadDurationSecondseSetting.description, preferredStyle: .actionSheet)
            let currentValue = max(UserDefaults.standard.double(forKey: crossfadDurationSecondseSetting.accessor), Constants.Settings.Options.crossfadeDurationSeconds[0])
            Constants.Settings.Options.crossfadeDurationSeconds.forEach { option in
                vc.addAction(.init(title: "\(currentValue == option ? "✔︎  " : "")\(Int(option)) seconds", style: .default) { _ in
                    UserDefaults.standard.set(option, forKey: crossfadDurationSecondseSetting.accessor)
                })
            }
            self.presentAlert(vc, animated: true, completion: nil)
        }

        let crossfadeOnNext = Constants.Settings.Info.crossfadeOnNext
        let crossfadeOnNextProvider = SwitchTableViewCellProvider(title: crossfadeOnNext.title, subTitle: crossfadeOnNext.description, isOn: false)
        UserDefaults.standard.bidirectionalBind(control: crossfadeOnNextProvider.uiSwitch.rx.isOn, keyPath: crossfadeOnNext.accessor, defaultValue: false).disposed(by: disposeBag)

        let crossfadeOnPrevious = Constants.Settings.Info.crossfadeOnPrevious
        let crossfadeOnPreviousProvider = SwitchTableViewCellProvider(title: crossfadeOnPrevious.title, subTitle: crossfadeOnPrevious.description, isOn: false)
        UserDefaults.standard.bidirectionalBind(control: crossfadeOnPreviousProvider.uiSwitch.rx.isOn, keyPath: crossfadeOnPrevious.accessor, defaultValue: false).disposed(by: disposeBag)

        let crossfadeSectionProvider = SpacingSectionProvider(providers: [crossfadeHeader, crossfadeProvider, crossfadeAtProvider, crossfadeDurationProvider, crossfadeOnNextProvider, crossfadeOnPreviousProvider], headerHeight: 0, footerHeight: 0)

        // MARK: - Up Next

        let upNextHeader = TitleTableViewSectionProvider(name: "UP NEXT")

        let upNextPreserve = Constants.Settings.Info.upNextPreserve
        let upNextPreserveProvider = SwitchTableViewCellProvider(title: upNextPreserve.title, subTitle: upNextPreserve.description, isOn: false)
        UserDefaults.standard.bidirectionalBind(control: upNextPreserveProvider.uiSwitch.rx.isOn, keyPath: upNextPreserve.accessor, defaultValue: false).disposed(by: disposeBag)

        let upNextQueueSectionProvider = SpacingSectionProvider(providers: [upNextHeader, upNextPreserveProvider], headerHeight: 5, footerHeight: 0)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.flix.build([crossfadeSectionProvider, upNextQueueSectionProvider])
        tableView.rx.didScroll.bind {
            self.shadowView.alpha = min(self.tableView.contentOffset.y / 300.0, 0.3)
        }.disposed(by: disposeBag)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        topLayoutGuideConstraint?.autoRemove()
        topLayoutGuideConstraint = tableView.autoPinEdge(toSuperviewEdge: .top, withInset: view.safeAreaInsets.top)
        view.layoutSubviews()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        shadowLayer.frame = CGRect(x: 0, y: 0, width: shadowView.frame.size.width, height: 10)
    }

    override func setupConstraints() {
        super.setupConstraints()

        tableView.autoPinEdge(toSuperviewEdge: .left)
        tableView.autoPinEdge(toSuperviewEdge: .right)
        tableView.autoPin(toBottomLayoutGuideOf: self, withInset: 0)

        shadowTopConstraint = shadowView.autoPinEdge(.top, to: .top, of: tableView)
        shadowView.autoPinEdge(toSuperviewEdge: .left)
        shadowView.autoPinEdge(toSuperviewEdge: .right)
        shadowView.autoSetDimension(.height, toSize: 21)
    }

}
