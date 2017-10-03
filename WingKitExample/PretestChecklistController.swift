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

    var reachabilityMonitor = ReachabilityMonitor()
    var sensorMonitor = SensorMonitor()
    var ambientNoiseMonitor = AmbientNoiseMonitor()

    @IBOutlet weak var startTestBarButton: UIBarButtonItem!
    @IBOutlet weak var internetConnectionCell: UITableViewCell!
    @IBOutlet weak var quietEnvironmentCell: UITableViewCell!
    @IBOutlet weak var sensorConnectionCell: UITableViewCell!

    override func viewDidLoad() {
        super.viewDidLoad()

        reachabilityMonitor.delegate = self
        sensorMonitor.delegate = self
        ambientNoiseMonitor.delegate = self

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
    }

    @IBAction func startTestButtonTapped(_ sender: Any) {

        Client.createTestSession { testSession, error in

            if let error = error {

                let alert = UIAlertController(
                    title: "Create Test Session Error",
                    message: "\(error)",
                    preferredStyle: .alert
                )

                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
                return
            }

            guard let testSession = testSession else {

                return
            }

            let sessionManager = TestSessionManager(testSession: testSession)

        }
    }

    func reloadStartTestEnabledState() {
        startTestBarButton.isEnabled = reachabilityMonitor.isConnectedToInternet
            && sensorMonitor.isPluggedIn
            && ambientNoiseMonitor.isBelowThreshold
    }

    func updateMonitorStatus() {

        internetConnectionCell.accessoryType = reachabilityMonitor.isConnectedToInternet ? .checkmark : .none
        quietEnvironmentCell.accessoryType = ambientNoiseMonitor.isBelowThreshold ? .checkmark : .none
        sensorConnectionCell.accessoryType = sensorMonitor.isPluggedIn ? .checkmark : .none

        reloadStartTestEnabledState()
    }
}

extension PretestChecklistController: SensorMonitorDelegate {

    func sensorStateDidChange(_ monitor: SensorMonitor) {
        sensorConnectionCell.accessoryType = sensorMonitor.isPluggedIn ? .checkmark : .none
        reloadStartTestEnabledState()
    }
}

extension PretestChecklistController: AmbientNoiseMonitorDelegate {

    func ambientNoiseMonitorDidChangeState(_ monitor: AmbientNoiseMonitor) {
        quietEnvironmentCell.accessoryType = ambientNoiseMonitor.isBelowThreshold ? .checkmark : .none
        reloadStartTestEnabledState()
    }
}

extension PretestChecklistController: ReachabilityMonitorDelegate {

    func reachabilityMonitorDidChangeReachability(_ monitor: ReachabilityMonitor) {
        internetConnectionCell.accessoryType = reachabilityMonitor.isConnectedToInternet ? .checkmark : .none
        reloadStartTestEnabledState()
    }
}
