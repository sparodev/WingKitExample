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

    let activityIndicatorStackView = UIStackView(frame: .zero)
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    let activityIndicatorMessageLabel = UILabel(frame: .zero)

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
            messageLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -20)
            ])

        if #available(iOS 11.0, *) {
            messageLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        } else {
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 84).isActive = true
        }

        activityIndicatorStackView.axis = .vertical
        activityIndicatorStackView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorStackView.alignment = .center
        activityIndicatorStackView.spacing = 5
        addSubview(activityIndicatorStackView)

        activityIndicatorStackView.addArrangedSubview(activityIndicator)

        activityIndicatorMessageLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        activityIndicatorMessageLabel.textAlignment = .center
        activityIndicatorMessageLabel.textColor = UIColor.gray
        activityIndicatorStackView.addArrangedSubview(activityIndicatorMessageLabel)

        NSLayoutConstraint.activate([
            activityIndicatorStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])

        signalStrengthCircle.backgroundColor = UIView.appearance().tintColor
        signalStrengthCircle.translatesAutoresizingMaskIntoConstraints = false
        signalStrengthCircle.clipsToBounds = true

        addSubview(signalStrengthCircle)

        signalStrengthCircleHeightConstraint = signalStrengthCircle.heightAnchor.constraint(equalToConstant: signalStrengthCircleInitialDiameter)
        signalStrengthCircleHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            signalStrengthCircle.widthAnchor.constraint(equalTo: widthAnchor),
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

    override func layoutSubviews() {
        super.layoutSubviews()

        signalStrengthCircle.layer.cornerRadius = frame.size.width/2
    }

    func showActivityIndicator(with message: String) {
        activityIndicatorMessageLabel.text = message
        activityIndicator.startAnimating()
        activityIndicatorStackView.isHidden = false
    }

    func hideActivityIndicator() {
        activityIndicator.stopAnimating()
        activityIndicatorStackView.isHidden = true
    }
}
