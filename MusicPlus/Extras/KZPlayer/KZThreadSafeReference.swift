//
//  KZThreadSafeReference.swift
//  Music+
//
//  Created by kezi on 2019/01/10.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation
import Realm

protocol RealmGenerating {
    func realmGenerator() -> (() -> Realm?)
}

extension RealmGenerating where Self: ThreadConfined {

    var safeReference: KZThreadSafeReference<Self> {
        return KZThreadSafeReference(to: self)
    }

}

class KZThreadSafeReference<T: RealmGenerating> where T: ThreadConfined {

    var reference: ThreadSafeReference<T>
    let realm: () -> Realm?

    init(to threadConfined: T) {
        reference = ThreadSafeReference(to: threadConfined)
        realm = threadConfined.realmGenerator()
    }

    func resolve() -> T? {
        guard let realm = realm() else {
            return nil
        }

        let resoloved = realm.resolve(reference)
        if let resoloved = resoloved {
            reference = ThreadSafeReference(to: resoloved)
        }
        return resoloved
    }

}
