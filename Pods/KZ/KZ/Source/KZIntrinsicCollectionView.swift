//
//  KZIntrinsicCollectionView.swift
//  KZ
//
//  Created by Kesi Maduka on 1/25/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
//

import UIKit

open class KZIntrinsicCollectionView: UICollectionView {

    override open var intrinsicContentSize : CGSize {
        self.layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: self.collectionViewLayout.collectionViewContentSize.height + 12)
    }
    
    override open func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
    }
}
