//
//  TestResultsViewController.swift
//  WingKitExample
//
//  Created by Matt Wahlig on 10/31/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import UIKit
import WingKit

protocol TableRow {
    var title: String { get set }
}

struct KeyValueRow: TableRow {
    var title: String
    var value: String?
}

struct ExhaleCurveRow: TableRow {
    var title: String
    var exhaleCurve: [[Double]]
}

struct TableSection {
    var title: String?
    var rows: [TableRow] = []

    init(title: String? = nil) {
        self.title = title
    }

    mutating func addRow(_ row: TableRow) {
        rows.append(row)
    }

    mutating func addRows(_ rows: [TableRow]) {
        for row in rows { addRow(row) }
    }
}

class ExhaleCurveGraphView: UIView {
    var curveWidth: CGFloat = 0
    var curveHeight: CGFloat = 0
    var rawExhaleCurve: [[Double]]?
    var dataPoints: [CGPoint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = .clear
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(withExhaleCurve exhaleCurve: [[Double]]) {
        rawExhaleCurve = exhaleCurve
        setNeedsDisplay()
    }

    func calculateDataPoints(fromExhaleCurve exhaleCurve: [[Double]], inRect rect: CGRect) -> [CGPoint] {
        let xScale = rect.size.width
        let yScale = -1 * rect.size.height

        return exhaleCurve.map { (volumeFlowTuple: [Double]) in
            let x = CGFloat(volumeFlowTuple[0])
            let y = CGFloat(volumeFlowTuple[1])
            return CGPoint(x: x * xScale,
                           y: frame.size.height + y * yScale)
        }
    }

    override func draw(_ rect: CGRect) {
        curveWidth = rect.size.width * 0.763
        curveHeight = rect.size.height * 0.192

        guard let exhaleCurve = rawExhaleCurve else {
            return
        }

        dataPoints = calculateDataPoints(fromExhaleCurve: exhaleCurve, inRect: rect)

        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setLineWidth(1.0)
        context.setStrokeColor(UIColor(red: 0.0/255.0, green: 177.0/255.0, blue: 211.0/255.0, alpha: 1.0).cgColor)
        var i = 0
        while i < dataPoints.count - 3 {

            context.move(to: dataPoints[i])

            context.addCurve(
                to: dataPoints[i + 3],
                control1: dataPoints[i + 1],
                control2: dataPoints[i + 2]
            )

            context.strokePath()

            i += 3
        }
        switch dataPoints.count - i {
        case 2:

            context.move(to: dataPoints[i])

            context.addLine(to: dataPoints[i + 1])

            context.strokePath()

        case 3:

            context.move(to: dataPoints[i])

            context.addQuadCurve(
                to: dataPoints[i + 2],
                control: dataPoints[i + 1]
            )

            context.strokePath()
        default:
            break
        }
    }
}

class ExhaleCurveCell: UITableViewCell {

    let edgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)

    let interitemPadding: CGFloat = 20
    let titleLabel = UILabel(frame: .zero)
    let exhaleCurveView = ExhaleCurveGraphView(frame: .zero)

    var rowModel: ExhaleCurveRow? {
        didSet {
            titleLabel.text = rowModel?.title
            exhaleCurveView.update(withExhaleCurve: rowModel?.exhaleCurve ?? [])
            setNeedsUpdateConstraints()
        }
    }

    fileprivate var didSetupConstraints = false

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        configureTitleLabel()
        configureExhaleCurveView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func configureTitleLabel() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        titleLabel.textAlignment = .left
        titleLabel.text = "Exhale Curve"
        contentView.addSubview(titleLabel)
    }

    fileprivate func configureExhaleCurveView() {
        exhaleCurveView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(exhaleCurveView)
    }

    override func updateConstraints() {
        if !didSetupConstraints {

            constrainViews()
            didSetupConstraints = true
        }

        super.updateConstraints()
    }

    fileprivate func constrainViews() {
        constrainTitleLabel()
        constrainExhaleCurveView()
    }

    fileprivate func constrainTitleLabel() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: edgeInsets.top),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: edgeInsets.left),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -edgeInsets.right)
            ])
    }

    fileprivate func constrainExhaleCurveView() {
        NSLayoutConstraint.activate([
            exhaleCurveView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 22),
            exhaleCurveView.leftAnchor.constraint(equalTo: titleLabel.leftAnchor),
            exhaleCurveView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -edgeInsets.right),
            exhaleCurveView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -edgeInsets.bottom),
            exhaleCurveView.heightAnchor.constraint(equalToConstant: 120)
            ])
    }

}

class ResultsCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        textLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        detailTextLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TestResultsViewController: UITableViewController {

    var testSession: TestSession!
    var sections: [TableSection]!

    lazy var doneBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(title: "Done", style: .plain,
                               target: self, action: #selector(doneButtonTapped(_:)))
    }()

    init(testSession: TestSession) {
        super.init(style: .plain)

        self.testSession = testSession

        sections = testSession.generateResultsTableContent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Test Results"
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = doneBarButtonItem

        tableView.register(ResultsCell.self, forCellReuseIdentifier: "TableCell")
        tableView.register(ExhaleCurveCell.self, forCellReuseIdentifier: "ExhaleCurveCell")
    }

    @objc func doneButtonTapped(_ button: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let rowModel = sections[indexPath.section].rows[indexPath.row]

        if let keyValueRow = rowModel as? KeyValueRow {

            let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath)

            cell.textLabel?.text = keyValueRow.title
            cell.detailTextLabel?.text = keyValueRow.value

            return cell


        } else if let exhaleCurveRow = rowModel as? ExhaleCurveRow {

            let cell = tableView.dequeueReusableCell(withIdentifier: "ExhaleCurveCell", for: indexPath) as! ExhaleCurveCell

            cell.rowModel = exhaleCurveRow

            return cell

        } else {
            return UITableViewCell()
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
}

fileprivate extension TestSession {

    func generateResultsTableContent() -> [TableSection] {

        var sections: [TableSection] = []

        let emptyValue = "--"

        var topLevelSection = TableSection()
        topLevelSection.addRows([
            KeyValueRow(title: "ID", value: id),
            KeyValueRow(title: "Started At", value: startedAt.iso8601),
            KeyValueRow(title: "Ended At", value: endedAt?.iso8601 ?? emptyValue),
            KeyValueRow(title: "Best Test Choice", value: bestTestChoice?.rawValue ?? emptyValue),
            KeyValueRow(title: "Lung Function Zone", value: lungFunctionZone?.rawValue ?? emptyValue),
            KeyValueRow(title: "Respiratory State", value: respiratoryState?.rawValue ?? emptyValue),
            KeyValueRow(title: "Reference Metric", value: referenceMetric.rawValue)
            ])

        if let pefPredicted = pefPredicted {
            topLevelSection.addRow(KeyValueRow(title: "PEF Predicted",
                                            value: ReferenceMetric.pef.formattedString(forValue: pefPredicted,
                                                                                       includeUnit: true)))
        }

        if let fev1Predicted = fev1Predicted {
            topLevelSection.addRow(KeyValueRow(title: "FEV1 Predicted",
                                            value: ReferenceMetric.fev1.formattedString(forValue: fev1Predicted,
                                                                                        includeUnit: true)))
        }

        sections.append(topLevelSection)

        if let bestTest = bestTest {
            sections.append(generateSection(withTitle: "Best Test", for: bestTest))
        }

        for (index, test) in tests.enumerated() {
            sections.append(generateSection(withTitle: "Test #\(index + 1)", for: test))
        }

        return sections
    }

    func generateSection(withTitle title: String, for test: Test) -> TableSection {
        let emptyValue = "--"

        var section = TableSection(title: title)

        section.addRows([
            KeyValueRow(title: "ID", value: test.id),
            KeyValueRow(title: "Status", value: test.status.rawValue),
            KeyValueRow(title: "Taken At", value: test.takenAt?.iso8601 ?? emptyValue)
            ])

        if let breathDuration = test.breathDuration {
            section.addRow(KeyValueRow(title: "Breath Duration", value: "\(Double(round(100 * breathDuration) / 100)) s"))
        }

        if let totalVolume = test.totalVolume {
            section.addRow(KeyValueRow(title: "Total Volume", value: "\(Double(round(100 * totalVolume) / 100)) L"))
        }

        if let pef = test.pef {
            section.addRow(KeyValueRow(title: "PEF", value: ReferenceMetric.pef.formattedString(forValue: pef,
                                                                                             includeUnit: true)))
        }

        if let fev1 = test.fev1 {
            section.addRow(KeyValueRow(title: "FEV1", value: ReferenceMetric.fev1.formattedString(forValue: fev1,
                                                                                               includeUnit: true)))
        }

        if let exhaleCurve = test.exhaleCurve {
            section.addRow(ExhaleCurveRow(title: "Exhale Curve", exhaleCurve: exhaleCurve))
        }

        return section
    }
}

extension Date {
    struct Formatter {
        static let iso8601: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: Calendar.Identifier.iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            return formatter
        }()

        static let iso8601WithMilliseconds: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: Calendar.Identifier.iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
            return formatter
        }()

        static func dateFromString(_ dateString: String) -> Date? {
            return Formatter.iso8601.date(from: dateString)
                ?? Formatter.iso8601WithMilliseconds.date(from: dateString)
        }
    }
    var iso8601: String { return Formatter.iso8601WithMilliseconds.string(from: self) }
}

extension String {
    var dateFromISO8601: Date? {
        return Date.Formatter.dateFromString(self)
    }
}

