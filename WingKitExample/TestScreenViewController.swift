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

    var manager: TestSessionManager!

    var sensorMonitor = SensorMonitor()
    var reachabilityMonitor = ReachabilityMonitor()

    // MARK: - Init

    init(manager: TestSessionManager) {
        super.init(nibName: nil, bundle: nil)

        self.manager = manager
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension TestScreenViewController: SensorMonitorDelegate {

    func sensorStateDidChange(_ monitor: SensorMonitor) {

    }
}

extension TestScreenViewController: ReachabilityMonitorDelegate {

    func reachabilityMonitorDidChangeReachability(_ monitor: ReachabilityMonitor) {

    }
}
