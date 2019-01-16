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

    override func viewDidLoad() {
        view.addSubview(tableView)
        super.viewDidLoad()

        title = "Settings"
        setupMenuToggle()

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
                    UserDefaults.standard.synchronize()
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
                    UserDefaults.standard.synchronize()
                })
            }
            self.presentAlert(vc, animated: true, completion: nil)
        }

        let crossfadeOnNext = Constants.Settings.Info.crossfadeOnNext
        let crossfadeOnNextProvider = SwitchTableViewCellProvider(title: crossfadeOnNext.title, subTitle: crossfadeOnNext.description, isOn: false)
        UserDefaults.standard.bidirectionalBind(control: crossfadeProvider.uiSwitch.rx.isOn, keyPath: crossfadeOnNext.accessor, defaultValue: false).disposed(by: disposeBag)

        let crossfadeOnPrevious = Constants.Settings.Info.crossfadeOnPrevious
        let crossfadeOnPreviousProvider = SwitchTableViewCellProvider(title: crossfadeOnPrevious.title, subTitle: crossfadeOnPrevious.description, isOn: false)
        UserDefaults.standard.bidirectionalBind(control: crossfadeProvider.uiSwitch.rx.isOn, keyPath: crossfadeOnPrevious.accessor, defaultValue: false).disposed(by: disposeBag)

        let crossfadeSectionProvider = SpacingSectionProvider(providers: [crossfadeProvider, crossfadeAtProvider, crossfadeDurationProvider, crossfadeOnNextProvider, crossfadeOnPreviousProvider], headerHeight: 20, footerHeight: 0)

        let upNextPreserve = Constants.Settings.Info.upNextPreserve
        let upNextPreserveProvider = SwitchTableViewCellProvider(title: upNextPreserve.title, subTitle: upNextPreserve.description, isOn: false)
        UserDefaults.standard.bidirectionalBind(control: upNextPreserveProvider.uiSwitch.rx.isOn, keyPath: upNextPreserve.accessor, defaultValue: false).disposed(by: disposeBag)

        let upNextQueueSectionProvider = SpacingSectionProvider(providers: [upNextPreserveProvider], headerHeight: 20, footerHeight: 0)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.flix.build([crossfadeSectionProvider, upNextQueueSectionProvider])

    }

    override func setupConstraints() {
        super.setupConstraints()
        tableView.autoPinEdgesToSuperviewEdges()
    }

}
