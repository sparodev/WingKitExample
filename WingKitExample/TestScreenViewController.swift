//
//  TestScreenViewController.swift
//  WingKitExample
//
//  Created by Matt Wahlig on 10/2/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import UIKit
import WingKit

class TestScreenViewController: UIViewController {

    var manager: TestSessionManager?

    var sensorMonitor = SensorMonitor()
    var reachabilityMonitor = ReachabilityMonitor()

    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
    }

    @IBAction func cancelButtonTapped() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension TestScreenViewController: SensorMonitorDelegate {

    func sensorStateDidChange(_ monitor: SensorMonitor) {

    }
}

extension TestScreenViewController: ReachabilityMonitorDelegate {

    func reachabilityMonitorDidChangeReachability(_ monitor: ReachabilityMonitor) {

    }
}
