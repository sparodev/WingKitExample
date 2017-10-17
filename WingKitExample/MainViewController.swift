//
//  MainViewController.swift
//  WingKitExample
//
//  Created by Matt Wahlig on 10/16/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    let startTestButton = UIButton(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        startTestButton.setTitle("Start Test", for: .normal)
        startTestButton.setTitleColor(UIView.appearance().tintColor, for: .normal)
        startTestButton.translatesAutoresizingMaskIntoConstraints = false
        startTestButton.addTarget(self, action: #selector(startTestButtonTapped), for: .touchUpInside)
        view.addSubview(startTestButton)

        NSLayoutConstraint.activate([
            startTestButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startTestButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
    }

    @objc func startTestButtonTapped() {

        let controller = UINavigationController(rootViewController: PretestChecklistController())

        if #available(iOS 11.0, *) {
            controller.navigationBar.prefersLargeTitles = true
        }

        controller.navigationBar.setValue(true, forKey: "hidesShadow")
        controller.navigationBar.barTintColor = .white
        controller.modalPresentationStyle = .fullScreen
        show(controller, sender: nil)
    }
}
