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
    var isExpanded: Bool { get set }

    func populateInitialSelectedValues(in pickerView: UIPickerView)
}

class PickerCell: UITableViewCell {

    var model: PickerDataSource? {
        didSet {
            pickerView.delegate = model
            pickerView.dataSource = model
            pickerView.isHidden = !(model?.isExpanded ?? false)

            pickerViewBottomConstraint?.isActive = model?.isExpanded ?? false

            model?.populateInitialSelectedValues(in: pickerView)

            setNeedsUpdateConstraints()
        }
    }

    let titleLabel = UILabel(frame: .zero)
    let valueLabel = UILabel(frame: .zero)
    let pickerView = UIPickerView(frame: .zero)

    fileprivate var pickerViewBottomConstraint: NSLayoutConstraint?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.clipsToBounds = true

        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        valueLabel.textColor = UIColor(red: 0.0/255.0, green: 177.0/255.0, blue: 211.0/255.0, alpha: 1.0)
        valueLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(valueLabel)

        pickerView.isHidden = true
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pickerView)

        pickerViewBottomConstraint = pickerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        pickerViewBottomConstraint?.priority = .defaultLow
        pickerViewBottomConstraint?.isActive = false

        NSLayoutConstraint.activate([
            titleLabel.leftAnchor.constraint(equalTo: layoutMarginsGuide.leftAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),

            valueLabel.rightAnchor.constraint(equalTo: layoutMarginsGuide.rightAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            pickerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            pickerView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            pickerView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            ])

        setNeedsUpdateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func expand() {

        model?.isExpanded = true

        pickerViewBottomConstraint?.isActive = true
        pickerView.isHidden = false

        setNeedsUpdateConstraints()
    }

    func collapse() {

        model?.isExpanded = false

        pickerViewBottomConstraint?.isActive = false
        pickerView.isHidden = true

        setNeedsUpdateConstraints()
    }
}

protocol GenericPickerCellModelDelegate: class {
    func pickerDidChangeSelectedOption(_ option: String)
}

class GenericPickerCellModel: NSObject, PickerDataSource {

    weak var delegate: GenericPickerCellModelDelegate?

    var isExpanded: Bool = false

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

    var isExpanded: Bool = false

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

    var client: Client
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

    init(client: Client) {
        self.client = client

        super.init(style: .plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Demographics"

        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .always
        }

        navigationItem.leftBarButtonItem = cancelBarButton
        navigationItem.rightBarButtonItem = nextBarButton

        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = false
        tableView.register(PickerCell.self, forCellReuseIdentifier: "PickerCell")

        updateNextButtonState()
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
            id: String(UUID().uuidString.prefix(20)),
            biologicalSex: biologicalSex,
            ethnicity: ethnicity,
            height: height,
            age: age
        )

        self.show(PretestChecklistController(client: client, patientData: patientData), sender: nil)
    }

    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let section = TableSection(rawValue: indexPath.section),
            let cell = tableView.dequeueReusableCell(withIdentifier: "PickerCell", for: indexPath) as? PickerCell else {
                return UITableViewCell()
        }

        cell.titleLabel.text = section.title

        switch section {
        case .age:

            cell.valueLabel.text = {
                if let age = age {
                    return "\(age)"
                } else {
                    return "Tap to Select"
                }
            }()
            cell.model = ageCellModel

        case .biologicalSex:

            cell.valueLabel.text = biologicalSex?.rawValue ?? "Tap to Select"
            cell.model = biologicalSexCellModel


        case .ethnicity:

            cell.valueLabel.text = ethnicity?.rawValue ?? "Tap to Select"
            cell.model = ethnicityCellModel

        case .height:

            cell.valueLabel.text = {
                if let height = height {
                    return "\(height / 12)' \(height % 12)\""
                } else {
                    return "Tap to Select"
                }
            }()
            cell.model = heightCellModel

        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard let selectedCell = tableView.cellForRow(at: indexPath) as? PickerCell else {
            return
        }

        tableView.beginUpdates()
        if let previousActiveIndexPath = activeIndexPath {

            if previousActiveIndexPath == indexPath {
                activeIndexPath = nil

                selectedCell.collapse()


            } else {

                if let previousActiveCell = tableView.cellForRow(at: previousActiveIndexPath) as? PickerCell {
                    previousActiveCell.collapse()
                }

                activeIndexPath = indexPath

                selectedCell.expand()
            }

        } else {

            activeIndexPath = indexPath
            selectedCell.expand()
        }

        tableView.endUpdates()

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
