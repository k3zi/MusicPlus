//
//  TintColorProvider.swift
//  MusicPlus
//
//  Created by kezi on 6/23/19.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Combine
import Foundation

protocol TintColorProvider {

    var tintColor: AnyPublisher<UIColor, Never> { get }

}
