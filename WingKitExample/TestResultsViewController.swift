//
//  TestResultsViewController.swift
//  WingKitExample
//
//  Created by Matt Wahlig on 10/31/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import UIKit
import WingKit

struct TableRow {
    var title: String
    var value: String
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

class TestResultsViewController: UITableViewController {

    var testSession: TestSession!
    var sections: [TableSection]!

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

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TableCell")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath)

        let row = sections[indexPath.section].rows[indexPath.row]

        cell.textLabel?.text = row.title
        cell.detailTextLabel?.text = row.value

        return cell
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
            TableRow(title: "ID", value: id),
            TableRow(title: "Started At", value: startedAt.iso8601),
            TableRow(title: "Ended At", value: endedAt?.iso8601 ?? emptyValue),
            TableRow(title: "Best Test Choice", value: bestTestChoice?.rawValue ?? emptyValue),
            TableRow(title: "Lung Function Zone", value: lungFunctionZone?.rawValue ?? emptyValue),
            TableRow(title: "Respiratory State", value: respiratoryState?.rawValue ?? emptyValue),
            ])

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
            TableRow(title: "ID", value: test.id),
            TableRow(title: "Status", value: test.status.rawValue),
            TableRow(title: "Taken At", value: test.takenAt?.iso8601 ?? emptyValue),
            TableRow(title: "Breath Duration", value: "\(test.breathDuration)"),
            TableRow(title: "Total Volume", value: "\(test.totalVolume)"),
            TableRow(title: "PEF", value: "\(test.pef)"),
            TableRow(title: "FEV1", value: "\(test.fev1)")
            ])

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

