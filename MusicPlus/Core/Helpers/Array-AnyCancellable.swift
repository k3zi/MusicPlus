//
//  Array-AnyCancellable.swift
//  MusicPlus
//
//  Created by kezi on 6/23/19.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Combine
import Foundation

func += <T>(lhs: inout [AnyCancellable], rhs: T) where T: Cancellable {
    lhs.append(AnyCancellable(rhs))
}
