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
        return UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
    }()

    lazy var startBarButton: UIBarButtonItem = {
        return UIBarButtonItem(title: "Start Test", style: .plain, target: self, action: #selector(startButtonTapped))
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

        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }

        recorder.delegate = self

        reachabilityMonitor.delegate = self
        sensorMonitor.delegate = self

        navigationItem.leftBarButtonItem = cancelBarButton
        navigationItem.rightBarButtonItem = startBarButton
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")

        if !recorder.skipRecording {
            do {
                try recorder.configure()
            } catch {

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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        reachabilityMonitor.stop()
        sensorMonitor.stop()
    }

    // MARK: - Button Actions

    @objc func startButtonTapped() {

        startBarButton.isEnabled = false

        recorder.startRecording()
    }

    @objc func cancelButtonTapped() {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    func updateStartButtonEnabledState() {
        startBarButton.isEnabled = recorder.state == .ready
            && reachabilityMonitor.isConnectedToInternet
            && (sensorMonitor.isPluggedIn || recorder.skipRecording)
    }

    // MARK: - Process Recording

    func processRecording() {

        testScreenView.showActivityIndicator(with: "UPLOADING")

        uploadRecording { (error) in

            if let error = error {

                let alert = UIAlertController(
                    title: "Upload Error",
                    message: "\(error)",
                    preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: "Cancel Test", style: .cancel, handler: { _ in
                    self.dismiss(animated: true, completion: {})
                }))

                alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: { _ in
                    self.transitionToNextTest()
                }))

                self.present(alert, animated: true, completion: nil)

                return
            }

            self.testScreenView.showActivityIndicator(with: "PROCESSING")

            self.sessionManager.refreshTestSession(completion: { (error) in

                self.testScreenView.hideActivityIndicator()

                if let error = error {

                    return
                }
                
                var alertMessage = ""
                var alertActions = [UIAlertAction]()
                
                let nextTestAction = UIAlertAction(title: "Next Test", style: .default, handler: { (_) in
                    self.transitionToNextTest()
                })
                
                let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: { (_) in
                    self.dismiss(animated: true, completion: nil)
                })
                
                switch self.sessionManager.state {
                case .goodTestFirst:
                    
                    alertMessage = "Your test was processed successfully. Tap Next to continue."
                    alertActions = [nextTestAction]
                    
                case .notProcessedTestFirst:
                    
                    alertMessage = "An error occurred while processing this test. Tap Next Test to try it again."
                    alertActions = [nextTestAction]
                    
                case .notReproducibleTestFirst:
                    
                    alertMessage = "An error occurred while processing this test. Tap Next Test to try it again."
                    alertActions = [nextTestAction]
                    
                case .notProcessedTestFinal:
                    
                    alertMessage = "Another processing error occurred. Start a new test session in order to try again."
                    alertActions = [dismissAction]
                    
                case .notReproducibleTestFinal:
                    
                    alertMessage = "The results from your tests aren't reproducible. Please begin a new test session to try again."
                    alertActions = [dismissAction]
                    
                case .reproducibleTestFinal:
                    
                    alertMessage = "You've completed the test session with reproducible results!"
                    alertActions = [dismissAction]
                default: return
                }
                
                let alert = UIAlertController(title: "Test Complete",
                                              message: alertMessage,
                                              preferredStyle: .alert)
                
                for action in alertActions {
                    alert.addAction(action)
                }

                self.present(alert, animated: true, completion: nil)
            })
        }
    }

    func uploadRecording(completion: @escaping (Error?) -> Void) {

        guard let recordingFilepath = recorder.recordingFilepath else {
            return
        }

        sessionManager.uploadRecording(atFilepath: recordingFilepath, completion: completion)
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

        guard !recorder.skipRecording else { return }

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

        updateStartButtonEnabledState()

        switch recorder.state {
        case .ready:

            if monitor.isConnectedToInternet {

                if let activeAlertController = activeAlert,
                    let alertReason = activeAlertReason,
                    alertReason == .internetDisconnected {

                    activeAlertController.dismiss(animated: true, completion: {
                        self.activeAlert = nil
                        self.activeAlertReason = nil
                    })
                }

            } else {

                self.presentTestInteruptionAlert(for: .internetDisconnected, actions: [
                    UIAlertAction(title: "Ok", style: .default, handler: nil)
                    ])
            }

        case .recording:

            if !monitor.isConnectedToInternet {
                self.presentTestInteruptionAlert(for: .internetDisconnected, actions: [
                    UIAlertAction(title: "Next Test", style: .default, handler: { (_) in
                        self.transitionToNextTest()
                    })]
                )
            }

        default: return
        }
    }
}

extension TestScreenViewController: TestRecorderDelegate {

    func recorderStateChanged(_ state: TestRecorderState) {
        switch state {
        case .recording: return
        case .finished:

            UIView.animate(withDuration: 0.3, delay: 0, options: [.beginFromCurrentState], animations: {
                self.testScreenView.signalStrengthCircleHeightConstraint?.constant = self.testScreenView.signalStrengthCircleInitialDiameter
                self.testScreenView.layoutIfNeeded()
            }, completion: nil)

            guard recorder.signalStrengthThresholdPassed || recorder.skipRecording  else {

                let alert = UIAlertController(
                    title: "Bad Recording",
                    message: "We weren't able to get a good recording that time. Let's try that again.",
                    preferredStyle: .alert)

                alert.addAction(UIAlertAction(
                    title: "Try Again",
                    style: .default, handler: { _ in
                        self.transitionToNextTest()
                }))

                self.present(alert, animated: true, completion: nil)
                return
            }

            processRecording()

        default: return
        }
    }

    func signalStrengthChanged(_ strength: Double) {
        print("Signal strength: \(strength)")

        let defaultAvailableSpace = testScreenView.frame.size.height - 100 - testScreenView.defaultSignalStrengthCircleVisibleHeight - (testScreenView.messageLabel.frame.origin.y + testScreenView.messageLabel.frame.size.height)
        let amountToScaleBy = CGFloat(strength) * defaultAvailableSpace
        let updatedHeight = self.testScreenView.signalStrengthCircleInitialDiameter + amountToScaleBy
        print("circle height: \(updatedHeight)")

        UIView.animate(withDuration: 0.1, delay: 0, options: [.beginFromCurrentState], animations: {
            self.testScreenView.signalStrengthCircleHeightConstraint?.constant = updatedHeight
            self.testScreenView.layoutIfNeeded()
        }, completion: nil)


    }
}
