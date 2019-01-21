//
//  RxSwift+Bidirectional.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/13.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

infix operator <-> : DefaultPrecedence

func <-><T: Comparable>(property: ControlProperty<T>, variable: Variable<T>) -> Disposable {
    let variableToProperty = variable.asObservable()
        .distinctUntilChanged()
        .bind(to: property)

    let propertyToVariable = property
        .distinctUntilChanged()
        .bind(to: variable)

    return CompositeDisposable(variableToProperty, propertyToVariable)
}

func <-><T: Comparable>(left: Variable<T>, right: Variable<T>) -> Disposable {
    let leftToRight = left.asObservable()
        .distinctUntilChanged()
        .bind(to: right)

    let rightToLeft = right.asObservable()
        .distinctUntilChanged()
        .bind(to: left)

    return CompositeDisposable(leftToRight, rightToLeft)
}

extension UserDefaults {
    func bidirectionalBind<T>(control: ControlProperty<T>, keyPath: String, defaultValue: T) -> Disposable {
        let first = UserDefaults.standard.rx.observe(T.self, keyPath).map { $0 ?? defaultValue }.bind(to: control)
        let second = control.bind(onNext: { value in
            UserDefaults.standard.set(value, forKey: keyPath)
        })

        return CompositeDisposable(first, second)
    }
}

extension Reactive where Base: UITableViewCell {
    /// Bindable sink for `hidden` property.
    public var isSelected: Binder<Bool> {
        return Binder(self.base) { view, hidden in
            view.isSelected = hidden
        }
    }
}
