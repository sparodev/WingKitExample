//
//  DemographicsViewController.swift
//  WingKitExample
//
//  Created by Matt Wahlig on 10/23/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import UIKit
import WingKit

protocol PickerDataSource: UIPickerViewDataSource, UIPickerViewDelegate {
    func populateInitialSelectedValues(in pickerView: UIPickerView)
}

class FormCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PickerCell: UITableViewCell {

    var model: PickerDataSource? {
        didSet {
            pickerView.delegate = model
            pickerView.dataSource = model

            model?.populateInitialSelectedValues(in: pickerView)
        }
    }

    let pickerView = UIPickerView(frame: .zero)

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        pickerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pickerView)

        NSLayoutConstraint.activate([
            pickerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            pickerView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            pickerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            pickerView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol GenericPickerCellModelDelegate: class {
    func pickerDidChangeSelectedOption(_ option: String)
}

class GenericPickerCellModel: NSObject, PickerDataSource {

    weak var delegate: GenericPickerCellModelDelegate?

    var title: String
    var options: [String]
    var selectedOption: String? {
        didSet {

            guard let selectedOption = selectedOption else {
                return
            }

            delegate?.pickerDidChangeSelectedOption(selectedOption)
        }
    }

    init(title: String, options: [String]) {
        self.title = title
        self.options = options
        self.selectedOption = options.first

        super.init()
    }

    func populateInitialSelectedValues(in pickerView: UIPickerView) {

        guard let selectedOption = selectedOption,
            let indexOfOption = options.index(of: selectedOption) else {
                return
        }

        pickerView.selectRow(indexOfOption, inComponent: 0, animated: false)
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedOption = options[row]
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return options[row]
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }
}

protocol HeightPickerCellModelDelegate: class {
    func heightPickerDidChangeSelection(_ height: Int)
}

class HeightPickerCellModel: NSObject, PickerDataSource {

    enum Component: Int {
        case feet
        case inches
    }

    weak var delegate: HeightPickerCellModelDelegate?

    fileprivate var feet: Int {
        get {
            guard let height = height else { return 0 }
            return height / 12
        }
        set {
            height = newValue * 12 + inches
        }
    }

    fileprivate var inches: Int {
        get {
            guard let height = height else { return 0 }
            return height % 12
        }
        set {
            height = feet * 12 + newValue
        }
    }

    /// The selected height (in inches).
    var height: Int? {
        didSet {
            delegate?.heightPickerDidChangeSelection(height ?? 0)
        }
    }

    func populateInitialSelectedValues(in pickerView: UIPickerView) {
        pickerView.selectRow(feet, inComponent: Component.feet.rawValue, animated: false)
        pickerView.selectRow(inches, inComponent: Component.inches.rawValue, animated: false)
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {

        guard let component = Component(rawValue: component) else {
            return nil
        }

        switch component {
        case .feet: return "\(row)'"
        case .inches: return "\(row)\""
        }
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let component = Component(rawValue: component) else {
            return 0
        }

        switch component {
        case .feet: return 9
        case .inches: return 12
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

        guard let component = Component(rawValue: component) else {
            return
        }

        switch component {
        case .feet: feet = row
        case .inches: inches = row
        }
    }
}

class DemographicsViewController: UITableViewController {

    enum TableSection: Int {
        case biologicalSex
        case age
        case height
        case ethnicity

        var title: String {
            switch self {
            case .biologicalSex: return "Biological Sex"
            case .age: return "Age"
            case .height: return "Height"
            case .ethnicity: return "Ethnicity"
            }
        }
    }

    var activeIndexPath: IndexPath?

    var biologicalSex: BiologlicalSex?
    var age: Int?
    var height: Int?
    var ethnicity: Ethnicity?

    lazy var cancelBarButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
    }()

    lazy var nextBarButton: UIBarButtonItem = {
        return UIBarButtonItem(title: "Next", style: .plain,
                               target: self, action: #selector(nextButtonTapped(_:)))
    }()

    lazy var biologicalSexCellModel: GenericPickerCellModel = {
        let model = GenericPickerCellModel(
            title: "Biological Sex",
            options: [
                BiologlicalSex.male.rawValue,
                BiologlicalSex.female.rawValue
        ])

        model.delegate = self

        return model
    }()
    
    lazy var ageCellModel: GenericPickerCellModel = {
        let model = GenericPickerCellModel(
            title: "Age",
            options: Array(1...100).map { return "\($0)" })

        model.delegate = self

        return model
    }()

    lazy var heightCellModel: HeightPickerCellModel = {
        let model = HeightPickerCellModel()

        model.delegate = self

        return model
    }()

    lazy var ethnicityCellModel: GenericPickerCellModel = {
        let model = GenericPickerCellModel(
            title: "Ethnicity",
            options: [
                Ethnicity.asian.rawValue,
                Ethnicity.black.rawValue,
                Ethnicity.nativeAmerican.rawValue,
                Ethnicity.pacificIslander.rawValue,
                Ethnicity.whiteHispanic.rawValue,
                Ethnicity.whiteNonHispanic.rawValue,
                Ethnicity.other.rawValue,
                Ethnicity.twoOrMore.rawValue
            ]
        )

        model.delegate = self

        return model
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Demographics"

        navigationItem.leftBarButtonItem = cancelBarButton
        navigationItem.rightBarButtonItem = nextBarButton

        tableView.register(FormCell.self, forCellReuseIdentifier: "FormCell")
        tableView.register(PickerCell.self, forCellReuseIdentifier: "PickerCell")
    }

    func updateNextButtonState() {
        nextBarButton.isEnabled = ethnicity != nil
            && biologicalSex != nil
            && age != nil
            && height != nil
    }

    @objc func nextButtonTapped(_ button: UIBarButtonItem) {

        guard let ethnicity = ethnicity else {

            updateNextButtonState()

            let alert = UIAlertController(title: "Invalid Ethnicity",
                                          message: "Please select an ethnicity in order to continue.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)

            return
        }

        guard let biologicalSex = biologicalSex else {

            updateNextButtonState()

            let alert = UIAlertController(title: "Invalid Biological Sex",
                                          message: "Please select a biological sex in order to continue.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)

            return
        }

        guard let age = age else {

            updateNextButtonState()

            let alert = UIAlertController(title: "Invalid Age",
                                          message: "Please select a valid age in order to continue.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)

            return
        }

        guard let height = height else {

            updateNextButtonState()

            let alert = UIAlertController(title: "Invalid Height",
                                          message: "Please select a valid height in order to continue.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)

            return
        }

        let patientData = PatientData(
            id: "5yEwdO6MVR8ZA",
            biologicalSex: biologicalSex,
            ethnicity: ethnicity,
            height: height,
            age: age
        )

        self.show(PretestChecklistController(patientData: patientData), sender: nil)
    }

    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 + (activeIndexPath?.section == section ? 1 : 0)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch indexPath.row {
        case 0: return formCell(in: tableView, at: indexPath)
        case 1: return pickerCell(in: tableView, at: indexPath)
        default: return UITableViewCell()
        }
    }

    func formCell(in tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        guard let section = TableSection(rawValue: indexPath.section),
            let cell = tableView.dequeueReusableCell(withIdentifier: "FormCell", for: indexPath) as? FormCell else {
                return UITableViewCell()
        }

        cell.textLabel?.text = section.title
        cell.detailTextLabel?.text = {
            switch section {
            case .age:
                if let age = age {
                    return "\(age)"
                } else {
                    return "Tap to Select"
                }
            case .biologicalSex: return biologicalSex?.rawValue ?? "Tap to Select"
            case .ethnicity: return ethnicity?.rawValue ?? "Tap to Select"
            case .height:

                if let height = height {
                    return "\(height / 12)' \(height % 12)\""
                } else {
                    return "Tap to Select"
                }
            }
        }()

        return cell
    }

    func pickerCell(in tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {

        guard let section = TableSection(rawValue: indexPath.section),
            let cell = tableView.dequeueReusableCell(withIdentifier: "PickerCell", for: indexPath) as? PickerCell else {
                return UITableViewCell()
        }

        switch section {
        case .age: cell.model = ageCellModel
        case .biologicalSex: cell.model = biologicalSexCellModel
        case .ethnicity: cell.model = ethnicityCellModel
        case .height: cell.model = heightCellModel
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return indexPath.row == 0 ? indexPath : nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if let previousActiveIndexPath = activeIndexPath {

            if previousActiveIndexPath == indexPath {
                activeIndexPath = nil
                tableView.deleteRows(at: [IndexPath(row: 1, section: previousActiveIndexPath.section)], with: .top)
            } else {

                activeIndexPath = indexPath

                let deletionAnimation: UITableViewRowAnimation = previousActiveIndexPath.section > indexPath.section ? .bottom : .top
//                let insertionAnimation: UITableViewRowAnimation = previousActiveIndexPath.section > indexPath.section ? .

                tableView.beginUpdates()
                tableView.deleteRows(at: [IndexPath(row: 1, section: previousActiveIndexPath.section)], with: deletionAnimation)
                tableView.insertRows(at: [IndexPath(row: 1, section: indexPath.section)], with: .top)
                tableView.endUpdates()
            }

        } else {

            activeIndexPath = indexPath
            tableView.insertRows(at: [IndexPath(row: 1, section: indexPath.section)], with: .top)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension DemographicsViewController: GenericPickerCellModelDelegate {

    func pickerDidChangeSelectedOption(_ option: String) {

        guard let activeIndexPath = activeIndexPath,
            let section = TableSection(rawValue: activeIndexPath.section) else {
                return
        }


        switch section {
        case .age: age = Int(option)
        case .biologicalSex: biologicalSex = BiologlicalSex(rawValue: option)
        case .ethnicity: ethnicity = Ethnicity(rawValue: option)
        default: return
        }

        tableView.reloadRows(at: [activeIndexPath], with: .none)
        updateNextButtonState()
    }
}

extension DemographicsViewController: HeightPickerCellModelDelegate {

    func heightPickerDidChangeSelection(_ height: Int) {

        guard let activeIndexPath = activeIndexPath,
            let section = TableSection(rawValue: activeIndexPath.section),
            section == .height else {
                return
        }

        self.height = height

        tableView.reloadRows(at: [activeIndexPath], with: .none)
        updateNextButtonState()
    }
}
