//
//  DoorTableViewCell.swift
//  ButterflyMX Demo
//
//  Created by Taras Markevych on 4/4/19.
//  Copyright © 2019 Taras Markevych. All rights reserved.
//

import UIKit
import BMXCore

class DoorTableViewCell: UITableViewCell {
    @IBOutlet weak var doorNameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func pleaseWait() {
        statusLabel.isHidden = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }

    func completeWith(_ text: String, color: UIColor) {
        activityIndicator.stopAnimating()
        statusLabel.isHidden = false
        statusLabel.text = text
        statusLabel.textColor = color
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: { [weak self] in
            self?.setDefault()
        })
    }

    private func setDefault() {
        statusLabel.textColor = Colors.mainBlue
        statusLabel.text = "Press to Open"
    }
}
