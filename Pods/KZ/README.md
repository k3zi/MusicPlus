## KZ ![Swift](https://img.shields.io/badge/language-Swift-orange.svg) [![CocoaPods](https://img.shields.io/cocoapods/v/KZ.svg)](http://cocoapods.org/pods/KZ) [![Build Status](https://travis-ci.org/k3zi/KZ.svg?branch=master)](https://travis-ci.org/k3zi/KZ)
A base framework for iOS projects

---

#### Install with CocoaPods
```
pod 'KZ', '~> 1.3'
```

## Classes Notes

##### `KZViewController` 
- A base for your controllers 
- Set any constraints in `updateViewConstraints`
- Override `fetchData` to handle any network requests (Note: this is called automatically and on 15 second intervals)
- UITableViewDelegate & UITableViewDataSource
   - Override `tableViewCellClass` to change the class of a cell
   - Override `tableViewCellData` to return the array of data to use for a section
   - Override `tableViewNoDataText` to change the text displayed when there is no data
   - This class already handles setting the height & content of cells

---

##### `KZTableViewController`
- Inherits from `KZViewController` 
- Can optionally create a table 
- Has an array of `Any` initialized beforehand: self.items
- The `tableView` is created by default and set to fill the whole view

---

##### `KZTableViewCell`
- Override `init(style:reuseIdentifier:)` to add any buttons, images, labels, etc...
- Override `setupConstraints` to handle laying out the cell's contents with autolayout
- Override `fillInCellData` to handle the data for the cell. The `model` property can be cast to the class you are expecting

---

##### `KZScrollViewController`
- Inherits from `KZViewController`
- Has a `contentView` embeded in a `scrollView` that fills the sceen
- Add any content in `viewDidLoad` to the `contentView`
- Override `setupConstraints` to layout the viewinside the scroll view

---

##### `KZIntrinsicTableView`
- A tableView whose height is the height of it's content

---

##### `KZIntrinsicCollectionView`
- A collectionView whose height is the height of it's content

---

## License
This library is available under the MIT license. See the LICENSE file for more info.

## Author
Kesi Maduka<br>
http://kez.io<br>
me@kez.io
