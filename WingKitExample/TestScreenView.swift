//
//  TestScreenView.swift
//  WingKitExample
//
//  Created by Matt Wahlig on 10/11/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import UIKit

class TestScreenView: UIView {

    let messageLabel = UILabel(frame: .zero)
    let signalStrengthCircle = UIView(frame: .zero)

    let defaultSignalStrengthCircleVisibleHeight: CGFloat = 100
    let signalStrengthCircleInitialDiameter: CGFloat = 400

    var signalStrengthCircleHeightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .white

        messageLabel.textColor = .black
        messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.text = "Tap on the start test button to begin the lung function measurement."
        messageLabel.numberOfLines = 0

        addSubview(messageLabel)

        NSLayoutConstraint.activate([
            messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            messageLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 20),
            messageLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -20),
            messageLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20)
            ])

        signalStrengthCircle.backgroundColor = UIColor(red: 0.0/255.0, green: 177.0/255.0, blue: 211.0/255.0, alpha: 1.0)
        signalStrengthCircle.layer.cornerRadius = signalStrengthCircleInitialDiameter/2
        signalStrengthCircle.translatesAutoresizingMaskIntoConstraints = false
        signalStrengthCircle.clipsToBounds = true

        addSubview(signalStrengthCircle)

        signalStrengthCircleHeightConstraint = signalStrengthCircle.heightAnchor.constraint(equalToConstant: signalStrengthCircleInitialDiameter)
        signalStrengthCircleHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            signalStrengthCircle.widthAnchor.constraint(equalToConstant: signalStrengthCircleInitialDiameter),
            signalStrengthCircle.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: signalStrengthCircleInitialDiameter - defaultSignalStrengthCircleVisibleHeight),
            signalStrengthCircle.centerXAnchor.constraint(equalTo: centerXAnchor),
            ])

        setNeedsUpdateConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


}
