//
//  ViewController.swift
//  WingKitExample
//
//  Created by Matt Wahlig on 9/27/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import WingKit
import UIKit

class PretestChecklistController: UITableViewController {

    enum TableRow: Int {
        case internetConnection
        case ambientNoise
        case sensorConnection

        var title: String {
            switch self {
            case .internetConnection: return "Internet Connected"
            case .ambientNoise: return "Quiet Environment"
            case .sensorConnection: return "Sensor Connected"
            }
        }
    }

    var reachabilityMonitor = ReachabilityMonitor()
    var sensorMonitor = SensorMonitor()
    var ambientNoiseMonitor = AmbientNoiseMonitor()

    lazy var cancelBarButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
    }()

    lazy var startTestBarButton: UIBarButtonItem = {
        return UIBarButtonItem(title: "Start Test", style: .plain,
                               target: self, action: #selector(startTestButtonTapped(_:)))
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Pre-test Checklist"

        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .always
        }

        navigationItem.rightBarButtonItem = startTestBarButton
        navigationItem.leftBarButtonItem = cancelBarButton

        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ReuseIdentifier")

        reachabilityMonitor.delegate = self
        sensorMonitor.delegate = self
        ambientNoiseMonitor.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

        do {
            try reachabilityMonitor.start()
            sensorMonitor.start()
            ambientNoiseMonitor.start(completion: { (error) in
                if let error = error {
                    let alert = UIAlertController(
                        title: "Ambient Noise Monitor Error",
                        message: "\(error)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.show(alert, sender: nil)
                }
            })
        } catch {
            let alert = UIAlertController(
                title: "Reachability Monitor Error",
                message: "\(error)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.show(alert, sender: nil)
        }

        updateMonitorStatus()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        reachabilityMonitor.stop()
        sensorMonitor.stop()
        ambientNoiseMonitor.stop()
    }

    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func startTestButtonTapped(_ sender: UIBarButtonItem) {

        sender.isEnabled = false

        Client.createTestSession { testSession, error in

            func handleError(_ error: Error? = nil) {

                sender.isEnabled = true

                if let error = error {
                    print("ERROR: \(error)")
                }

                let alert = UIAlertController(
                    title: "Create Test Session Error",
                    message: "An error occurred while starting the test session. Please try again.",
                    preferredStyle: .alert
                )

                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }

            if let error = error {
                handleError(error)
                return
            }

            guard let testSession = testSession else {
                handleError()
                return
            }

            self.show(TestScreenViewController(sessionManager: TestSessionManager(testSession: testSession)),
                      sender: nil)
            sender.isEnabled = true
        }
    }

    func reloadStartTestEnabledState() {
        startTestBarButton.isEnabled = reachabilityMonitor.isConnectedToInternet
            && sensorMonitor.isPluggedIn
            && ambientNoiseMonitor.isBelowThreshold
    }

    func updateMonitorStatus() {

        updateAccessoryType(to: reachabilityMonitor.isConnectedToInternet ? .checkmark : .none,
                            for: TableRow.internetConnection)

        updateAccessoryType(to: ambientNoiseMonitor.isBelowThreshold ? .checkmark : .none,
                            for: TableRow.ambientNoise)

        updateAccessoryType(to: sensorMonitor.isPluggedIn ? .checkmark : .none,
                            for: TableRow.sensorConnection)

        reloadStartTestEnabledState()
    }

    func updateAccessoryType(to type: UITableViewCellAccessoryType, for row: TableRow) {
        tableView.cellForRow(at: IndexPath(row: row.rawValue, section: 0))?.accessoryType = type
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ReuseIdentifier", for: indexPath)

        guard let row = TableRow(rawValue: indexPath.row) else { return cell }

        cell.textLabel?.text = row.title

        switch row {
        case .internetConnection: cell.accessoryType = reachabilityMonitor.isConnectedToInternet ? .checkmark : .none
        case .ambientNoise: cell.accessoryType = ambientNoiseMonitor.isBelowThreshold ? .checkmark : .none
        case .sensorConnection: cell.accessoryType = sensorMonitor.isPluggedIn ? .checkmark : .none
        }

        return cell
    }
}

extension PretestChecklistController: SensorMonitorDelegate {

    func sensorStateDidChange(_ monitor: SensorMonitor) {
        updateAccessoryType(to: sensorMonitor.isPluggedIn ? .checkmark : .none,
                            for: TableRow.sensorConnection)
        reloadStartTestEnabledState()
    }
}

extension PretestChecklistController: AmbientNoiseMonitorDelegate {

    func ambientNoiseMonitorDidChangeState(_ monitor: AmbientNoiseMonitor) {
        updateAccessoryType(to: ambientNoiseMonitor.isBelowThreshold ? .checkmark : .none,
                            for: TableRow.ambientNoise)
        reloadStartTestEnabledState()
    }
}

extension PretestChecklistController: ReachabilityMonitorDelegate {

    func reachabilityMonitorDidChangeReachability(_ monitor: ReachabilityMonitor) {
        updateAccessoryType(to: reachabilityMonitor.isConnectedToInternet ? .checkmark : .none,
                            for: TableRow.internetConnection)
        reloadStartTestEnabledState()
    }
}
