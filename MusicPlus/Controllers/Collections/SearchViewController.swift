//
//  SearchViewController.swift
//  MusicPlus
//
//  Created by kezi on 2019/01/27.
//  Copyright © 2019 Kesi Maduka. All rights reserved.
//

import Foundation

enum SearchStep {
    case fieldSelect
    case comparisonSelect(property: FilterableProperty)
    case valueSelect(property: FilterableProperty, comparison: FilterComparison)
}

enum FilterComparison {
    case equal
    case notEqual
    case greaterThan
    case greaterThanOrEqual
    case lessThan
    case lessThanOrEqual

    var displayName: String {
        switch self {
        case .equal:
            return "is equal to"
        case .notEqual:
            return "is not equal to"
        case .greaterThan:
            return "is greater than"
        case .greaterThanOrEqual:
            return "is greater than or equal to"
        case .lessThan:
            return "is less than"
        case .lessThanOrEqual:
            return "is less than or equal to"
        }
    }

    var shortDisplayName: String {
        switch self {
        case .equal:
            return "="
        case .notEqual:
            return "≠"
        case .greaterThan:
            return ">"
        case .greaterThanOrEqual:
            return "≧"
        case .lessThan:
            return "<"
        case .lessThanOrEqual:
            return "≦"
        }
    }

}

struct FilterableProperty {

    let keyPath: AnyKeyPath
    let displayName: String
    let shortDisplayName: String

    var possibleComparisons: [FilterComparison] {
        var result = [FilterComparison]()
        switch keyPath {
        case is KeyPath<KZPlayerItem, Int>, is KeyPath<KZPlayerItem, Double>:
            result.append(contentsOf: [.equal, .notEqual, .greaterThan, .greaterThanOrEqual, .lessThan, .lessThanOrEqual])
        default:
            break
        }

        return result
    }

}

class FilterItem {
    let property: FilterableProperty
    let comparison: FilterComparison

    init(property: FilterableProperty, comparison: FilterComparison) {
        self.property = property
        self.comparison = comparison
    }
}

class SearchViewController: KZViewController {

    static let shared = SearchViewController()
    var tableView = UITableView(frame: .zero, style: .plain)
    let shadowView = UIView()
    let shadowLayer = CAGradientLayer()
    var shadowTopConstraint: NSLayoutConstraint?
    var topLayoutGuideConstraint: NSLayoutConstraint?

    let addFilterButton = MPTitleHeaderView(frame: .zero)

    var pickerView: UIPickerView?
    var toolbar: UIToolbar?
    var step = SearchStep.fieldSelect
    var filterableProperties = [FilterableProperty]()
    var stepLabel = UILabel()

    var filterItems = [FilterItem]()

    // MARK: Setup View

    override func viewDidLoad() {
        fetchAUtomatically = false
        super.viewDidLoad()

        title = "Advanced Search"
        view.backgroundColor = .clear

        setupMenuToggle()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.sectionIndexBackgroundColor = .clear
        tableView.sectionIndexColor = .white
        tableView.tableHeaderView = UIView.init(frame: .init(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        tableView.contentInsetAdjustmentBehavior = .always
        view.addSubview(tableView)

        shadowView.backgroundColor = .clear
        shadowLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        shadowLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        shadowLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        shadowView.layer.insertSublayer(shadowLayer, at: 0)
        shadowView.alpha = 0.0
        view.addSubview(shadowView)

        addFilterButton.label.text = "Add Filter"
        addFilterButton.imageView.image = #imageLiteral(resourceName: "addButton")
        addFilterButton.imageView.tintColor = .white
        addFilterButton.addTarget(self, action: #selector(addFilter), for: .touchUpInside)
        tableView.tableHeaderView = addFilterButton

        tableView.register(cellType: FilterTableViewCell.self)

        filterableProperties.append(FilterableProperty(keyPath: \KZPlayerItem.playCount as AnyKeyPath, displayName: "Play Count", shortDisplayName: "Plays"))
        filterableProperties.append(FilterableProperty(keyPath: \KZPlayerItem.bpm as AnyKeyPath, displayName: "Beats Per Minute", shortDisplayName: "BPM"))
        filterableProperties.append(FilterableProperty(keyPath: \KZPlayerItem.duration as AnyKeyPath, displayName: "Duration (Minutes)", shortDisplayName: "Duration"))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        shadowLayer.frame = CGRect(x: 0, y: 0, width: shadowView.frame.size.width, height: 10)

        topLayoutGuideConstraint?.autoRemove()
        topLayoutGuideConstraint = tableView.autoPinEdge(toSuperviewEdge: .top, withInset: view.safeAreaInsets.top)
        view.layoutSubviews()
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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        shadowView.alpha = min(scrollView.contentOffset.y / 300.0, 0.3)
    }

    @objc func addFilter() {
        guard self.pickerView == nil else {
            return
        }

        let pickerView = UIPickerView(frame: .zero)
        view.addSubview(pickerView)
        pickerView.autoPinEdge(toSuperviewEdge: .left)
        pickerView.autoPinEdge(toSuperviewEdge: .right)
        pickerView.autoPin(toBottomLayoutGuideOf: self, withInset: 0)

        let toolbar = UIToolbar(frame: .zero)
        view.addSubview(toolbar)
        toolbar.autoPinEdge(toSuperviewEdge: .left)
        toolbar.autoPinEdge(toSuperviewEdge: .right)
        toolbar.autoPinEdge(.bottom, to: .top, of: pickerView)

        pickerView.backgroundColor = .white
        pickerView.delegate = self
        pickerView.dataSource = self

        step = .fieldSelect
        stepLabel.text = stepTitle

        self.pickerView = pickerView
        self.toolbar = toolbar

        reloadToolbar()
    }

    func reloadToolbar() {
        stepLabel.text = stepTitle

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelFilter))
        let spacerView1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let titleView = UIBarButtonItem(customView: stepLabel)
        let spacerView2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""), style: .plain, target: self, action: #selector(nextStep))
        toolbar?.setItems([cancelButton, spacerView1, titleView, spacerView2, doneButton], animated: true)
    }

    @objc func cancelFilter() {
        self.pickerView?.removeFromSuperview()
        self.toolbar?.removeFromSuperview()
        self.pickerView = nil
        self.toolbar = nil
    }

    @objc func nextStep() {
        guard let pickerView = pickerView else {
            return
        }

        let row = pickerView.selectedRow(inComponent: 0)
        switch step {
        case .fieldSelect:
            step = .comparisonSelect(property: filterableProperties[row])
            reloadToolbar()
            pickerView.reloadAllComponents()
        case .comparisonSelect(let property):
            // step = .valueSelect(property: property, comparison: property.possibleComparisons[row])
            self.cancelFilter()
            filterItems.append(FilterItem(property: property, comparison: property.possibleComparisons[row]))
            tableView.reloadData()
        case .valueSelect(let property, let comparison):
        break
        }
    }

    var stepTitle: String {
        switch step {
        case .fieldSelect: return "①・②"
        case .comparisonSelect(let property): return "\(property.shortDisplayName)・②"
        default: return ""
        }
    }

    override func tableViewCellClass(_ tableView: UITableView, indexPath: IndexPath?) -> KZTableViewCell.Type {
        return FilterTableViewCell.self
    }

    override func tableViewCellData(_ tableView: UITableView, section: Int) -> [Any] {
        return filterItems as [Any]
    }

}

extension SearchViewController: UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch step {
        case .fieldSelect:
            return filterableProperties[row].displayName
        case .comparisonSelect(let property):
            return property.possibleComparisons[row].displayName
        default:
            return nil
        }
    }

}

extension SearchViewController: UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch step {
        case .fieldSelect:
            return filterableProperties.count
        case .comparisonSelect(let property):
            return property.possibleComparisons.count
        default:
            return 0
        }
    }

}
