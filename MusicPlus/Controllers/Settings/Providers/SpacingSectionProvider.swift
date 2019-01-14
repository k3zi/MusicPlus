//
//  SpacingSectionProvider.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/13.
//  Copyright © 2019 Storm Edge Apps LLC. All rights reserved.
//

import Foundation
import Flix

class SpacingSectionProvider: AnimatableTableViewSectionProvider {

    convenience init(providers: [_AnimatableTableViewMultiNodeProvider], headerHeight: CGFloat, footerHeight: CGFloat) {
        let headerProvider = UniqueCustomTableViewSectionProvider(tableElementKindSection: .header)
        headerProvider.backgroundView = UIView()
        headerProvider.sectionHeight = { _ in return headerHeight }
        let footerProvider = UniqueCustomTableViewSectionProvider(tableElementKindSection: .footer)
        footerProvider.backgroundView = UIView()
        footerProvider.sectionHeight = { _ in return footerHeight }
        self.init(providers: providers, headerProvider: headerProvider, footerProvider: footerProvider)
    }

}
