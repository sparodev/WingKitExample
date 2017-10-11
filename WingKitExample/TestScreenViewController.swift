//
//  TestScreenViewController.swift
//  WingKitExample
//
//  Created by Matt Wahlig on 10/2/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import UIKit
import WingKit

enum LocalTestFailureReason {
    case sensorDisconnected
    case internetDisconnected
    case blowLevelThresholdNotMet

    var title: String {
        switch self {
        case .sensorDisconnected: return "Sensor Error"
        case .internetDisconnected: return "Internet Error"
        case .blowLevelThresholdNotMet: return "Processing Error"
        }
    }

    var subtitle: String {
        switch self {
        case .sensorDisconnected: return "Where's the sensor?"
        case .internetDisconnected: return "No Internet Connection"
        case .blowLevelThresholdNotMet: return "Something went wrong!"
        }
    }

    var message: String {
        switch self {
        case .sensorDisconnected:
            return "Be sure Wing is plugged in and be careful not to pull on the cord when blowing into Wing!"
        case .internetDisconnected:
            return "You must be connected to the internet in order to take a test. "
                + "Please fix your connection and try again."
        case .blowLevelThresholdNotMet:
            return "Let's try doing that test again!"
        }
    }
}

class TestScreenViewController: UIViewController {

    var testScreenView: TestScreenView!
    var sessionManager: TestSessionManager
    var recorder = TestSessionRecorder()

    lazy var cancelBarButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        button.tintColor = UIColor(red: 0.0/255.0, green: 177.0/255.0, blue: 211.0/255.0, alpha: 1.0)
        return button
    }()

    lazy var startBarButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Start Test", style: .plain, target: self, action: #selector(startButtonTapped))
        button.tintColor = UIColor(red: 0.0/255.0, green: 177.0/255.0, blue: 211.0/255.0, alpha: 1.0)
        return button
    }()

    var sensorMonitor = SensorMonitor()
    var reachabilityMonitor = ReachabilityMonitor()

    var baselineBlowBackground = 0.5

    var activeAlert: UIAlertController? {
        didSet {
            if activeAlert == nil {
                activeAlertReason = nil
            }
        }
    }
    var activeAlertReason: LocalTestFailureReason?

    init(sessionManager: TestSessionManager) {
        self.sessionManager = sessionManager

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func loadView() {
        testScreenView = TestScreenView(frame: .zero)
        view = testScreenView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        recorder.delegate = self

        reachabilityMonitor.delegate = self
        sensorMonitor.delegate = self

        navigationItem.leftBarButtonItem = cancelBarButton
        navigationItem.rightBarButtonItem = startBarButton
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

        do {
            try reachabilityMonitor.start()
        } catch {

            let alert = UIAlertController(
                title: "Network Monitor Error",
                message: "An error occurred while checking your network status: \(error)", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                alert.dismiss(animated: true, completion: {
                    self.dismiss(animated: true, completion: nil)
                })
            }))

            self.present(alert, animated: true, completion: nil)
        }

        sensorMonitor.start()

        if !sensorMonitor.isPluggedIn {
            let alert = UIAlertController(title: "Where's the sensor?", message: "Be sure Wing is plugged in and be careful not to pull on the cord when blowing into Wing!", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                alert.dismiss(animated: true, completion: {
                    self.dismiss(animated: true, completion: nil)
                })
            }))
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        reachabilityMonitor.stop()
        sensorMonitor.stop()
    }

    @objc func startButtonTapped() {

        startBarButton.isEnabled = false

        recorder.startRecording()
    }

    @objc func cancelButtonTapped() {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    func uploadRecording() {

        guard let recordingFilepath = recorder.recordingFilepath else {

            let alert = UIAlertController(
                title: "Recording Error",
                message: "An error occurred while recording your test. Please try again.",
                preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: { _ in
                self.transitionToNextTest()
            }))

            present(alert, animated: true, completion: nil)

            return
        }

        sessionManager.uploadRecording(atFilepath: recordingFilepath) { (error) in

            if let error = error {
                let alert = UIAlertController(
                    title: "Upload Error",
                    message: "\(error)",
                    preferredStyle: .alert)
                return
            }


        }
    }

    func transitionToNextTest() {
        self.show(TestScreenViewController(sessionManager: sessionManager), sender: nil)
    }

    func presentTestInteruptionAlert(for reason: LocalTestFailureReason, actions: [UIAlertAction]) {

        let alert = UIAlertController(title: reason.title, message: reason.message, preferredStyle: .alert)

        for action in actions {
            alert.addAction(action)
        }

        present(alert, animated: true) {
            self.activeAlert = alert
            self.activeAlertReason = reason
        }
    }
}

extension TestScreenViewController: SensorMonitorDelegate {

    func sensorStateDidChange(_ monitor: SensorMonitor) {

        switch recorder.state {
        case .ready:

            startBarButton.isEnabled = monitor.isPluggedIn && reachabilityMonitor.isConnectedToInternet

            if monitor.isPluggedIn {

                if let alertReason = activeAlertReason, alertReason == .sensorDisconnected {
                    activeAlert?.dismiss(animated: true, completion: {
                        self.activeAlertReason = nil
                        self.activeAlert = nil
                    })
                }

            } else {

                let alert = UIAlertController(
                    title: "Sensor Disconnected",
                    message: "It appears the sensor disconnected. Plug it back in to resume the test or tap cancel to end the test.", preferredStyle: .alert)

                alert.addAction(UIAlertAction(
                    title: "Cancel Test",
                    style: .destructive,
                    handler: { _ in

                        self.dismiss(animated: true, completion: nil)
                }))

                present(alert, animated: true, completion: nil)
            }

        case .recording:

            guard !monitor.isPluggedIn else { return }

            let alert = UIAlertController(
                title: "Sensor Disconnected",
                message: "It appears the sensor disconnected while recording. Plug it back in and let's try that again.", preferredStyle: .alert)

            alert.addAction(UIAlertAction(
                title: "Ok",
                style: .default,
                handler: { _ in

                    self.transitionToNextTest()
            }))

            present(alert, animated: true, completion: nil)

        default: return
        }
    }
}

extension TestScreenViewController: ReachabilityMonitorDelegate {

    func reachabilityMonitorDidChangeReachability(_ monitor: ReachabilityMonitor) {

    }
}

extension TestScreenViewController: TestRecorderDelegate {

    func recorderStateChanged(_ state: TestRecorderState) {
        switch state {
        case .recording: return
        case .finished:

            guard recorder.signalStrengthThresholdPassed else {

                let alert = UIAlertController(
                    title: "Bad Recording",
                    message: "We weren't able to get a good recording that time. Let's try that again.",
                    preferredStyle: .alert)

                alert.addAction(UIAlertAction(
                    title: "Try Again",
                    style: .default, handler: { _ in
                        self.transitionToNextTest()
                }))
                return
            }

            uploadRecording()

        default: return
        }
    }

    func signalStrengthChanged(_ strength: Double) {
        print("Signal strength: \(strength)")
    }
}
