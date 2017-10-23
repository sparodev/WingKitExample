//
//  DemographicsViewController.swift
//  WingKitExample
//
//  Created by Matt Wahlig on 10/23/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import UIKit

protocol PickerDataSource: UIPickerViewDataSource {
    var identifier: String { get }

    var selectedItem: Any? { get }

    func titleForRow(_ row: Int, component: Int) -> String?
    func selectItem(at row: Int, component: Int)
    func rowForSelectedObject(inComponent component: Int) -> Int?
    func stringValue() -> String?
}

class PickerCell: UITableViewCell {

    var model: PickerCellModel? {
        didSet {
            self.reloadData()
        }
    }

    let titleLabel = UILabel(frame: .zero)
    let valueLabel = UILabel(frame: .zero)
    let pickerView = UIPickerView(frame: .zero)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .left

        contentView.addSubview(titleLabel)

        valueLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        valueLabel.textColor = UIColor(white: 0.3, alpha: 1)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.textAlignment = .right

        contentView.addSubview(valueLabel)

        pickerView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func reloadData() {
        guard let model = model else {
            return
        }

        titleLabel.text = model.title
        valueLabel.text = model.value
    }

    static func reuseIdentifier() -> String {
        return "PickerCell"
    }
}

class PickerCellModel {

    var pickerDataSource: PickerDataSource

    var title: String
    var value: String? { return pickerDataSource.stringValue() }

    init(title: String, dataSource: PickerDataSource) {
        self.title = title
        self.pickerDataSource = dataSource
    }
}

class HeightPickerDataSource: NSObject, PickerDataSource {

    let maxFeet = 9

    enum Component: Int {
        case feet
        case inches
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let component = Component(rawValue: component) else { return 0 }

        switch component {
        case .feet: return maxFeet
        case .inches: return 12
        }
    }

    var identifier: String
    var selectedItem: Any? {
        return selectedHeight
    }

    var selectedHeight: Int?

    var selectedFeet: Int {
        get {
            guard let height = selectedHeight else { return 0 }
            return height / 12
        }
        set {
            var updatedHeight = selectedHeight ?? 0
            updatedHeight += (newValue - selectedFeet) / 12
            selectedHeight = updatedHeight
        }
    }

    var selectedInches: Int {
        get {
            guard let height = selectedHeight else { return 0 }
            return height % 12
        }
        set {
            var updatedHeight = selectedHeight ?? 0
            updatedHeight += newValue - selectedInches
            selectedHeight = updatedHeight
        }
    }

    init(identifier: String, height: Int? = nil) {
        self.identifier = identifier

        super.init()

        self.selectedHeight = height
    }

    func titleForRow(_ row: Int, component: Int) -> String? {
        guard let component = Component(rawValue: component) else { return nil }

        switch component {
        case .feet where row >= 0 && row <= maxFeet: return "\(row)'"
        case .inches where row >= 0 && row <= 12: return "\(row)\""
        default: return nil
        }
    }

    func selectItem(at row: Int, component: Int) {
        guard let component = Component(rawValue: component) else { return }

        switch component {
        case .feet: selectedFeet = row
        case .inches: selectedInches = row
        }

    }

    func rowForSelectedObject(inComponent component: Int) -> Int? {
        guard let component = Component(rawValue: component) else { return nil }

        switch component {
        case .feet: return selectedFeet
        case .inches: return selectedInches
        }
    }

    func stringValue() -> String? {

        guard let height = selectedHeight else { return nil }

        let feet = height / 12
        let inches = height % 12

        var formattedString = ""

        if feet != 0 {
            formattedString += "\(feet)'"
            if inches != 0 {
                formattedString += " "
            }
        }

        if inches != 0 {
            formattedString += "\(inches)\""
        }

        return formattedString
    }
}

class EnumPickerDataSource<E: RawRepresentable>: NSObject, PickerDataSource where E.RawValue == String {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }

    var identifier: String

    var selectedItem: Any?
    var options: [E]

    init(options: [E]) {
        self.options = options
    }

    func titleForRow(_ row: Int, component: Int) -> String? {
        return options[row].rawValue.capitalized
    }

    func selectItem(at row: Int, component: Int) {
        selectedItem = options[row]
    }

    func rowForSelectedObject(inComponent component: Int) -> Int? {
        <#code#>
    }

    func stringValue() -> String? {
        return
    }


}

class DemographicsViewController: UITableViewController {

    enum TableRow: Int {
        case biologicalSex
        case age
        case height
        case ethnicity
    }

    var biologicalSexCellModel = PickerCellModel(title: "Biological Sex")
    var ageCellModel = PickerCellModel(title: "Age")
    var heightCellModel = PickerCellModel(title: "Height", dataSource: HeightPickerDataSource(identifier: "height"))
    var ethnicityCellModel = PickerCellModel(title: "Ethnicity")

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Demographics"

        tableView.register(PickerCell.self, forCellReuseIdentifier: PickerCell.reuseIdentifier())
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PickerCell.reuseIdentifier(), for: indexPath) as? PickerCell else {
                return UITableViewCell()
        }

        switch indexPath.row {
        case TableRow.biologicalSex.rawValue: break
        default: break
        }

        return cell
    }
}
