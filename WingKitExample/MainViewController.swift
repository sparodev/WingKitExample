//
//  MainViewController.swift
//  WingKitExample
//
//  Created by Matt Wahlig on 10/16/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import UIKit
import WingKit

class MainViewController: UIViewController {

    let startTestButton = UIButton(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        startTestButton.layer.cornerRadius = 8
        startTestButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 30, bottom: 10, right: 30)
        startTestButton.clipsToBounds = true
        startTestButton.setTitle("Start Test", for: .normal)
        startTestButton.setTitleColor(UIView.appearance().tintColor, for: .normal)
        startTestButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        startTestButton.setBackgroundImage(UIImage.from(color: UIColor.white), for: .normal)
        startTestButton.setBackgroundImage(UIImage.from(color: UIColor(white: 0.95, alpha: 1)), for: .highlighted)
        startTestButton.translatesAutoresizingMaskIntoConstraints = false
        startTestButton.addTarget(self, action: #selector(startTestButtonTapped), for: .touchUpInside)
        view.addSubview(startTestButton)

        NSLayoutConstraint.activate([
            startTestButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startTestButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
    }

    @objc func startTestButtonTapped() {

        let client = Client()
        client.token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IktyNDJ5b2pHdzM4V3oiLCJ0eXBlIjoiYXV0aCIsImtleUdlbiI6IjEyRUJBYmxnTHJOSlAiLCJpYXQiOjE1MDk0NzU1ODcsImV4cCI6MTU0MTAxMTU4N30.PG6wEYDBwuZeWaUhIQGRPtH1UwiFqBXHs-zOqkuP3CI"

        let controller = UINavigationController(rootViewController: DemographicsViewController(client: client))

        if #available(iOS 11.0, *) {
            controller.navigationBar.prefersLargeTitles = true
        }

        controller.navigationBar.setValue(true, forKey: "hidesShadow")
        controller.navigationBar.barTintColor = .white
        controller.modalPresentationStyle = .fullScreen
        show(controller, sender: nil)
    }
}

extension UIImage {
    static func from(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
