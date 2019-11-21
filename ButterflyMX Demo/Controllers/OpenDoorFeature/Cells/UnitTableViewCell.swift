//
//  UnitTableViewCell.swift
//  ButterflyMX Demo
//
//  Created by Taras Markevych on 4/4/19.
//  Copyright © 2019 Taras Markevych. All rights reserved.
//

import UIKit
import BMXCore
class UnitTableViewCell: UITableViewCell {

    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!

    func setTenant(_ data: TenantModel) {
        unitLabel.text = "Unit: " + (data.unit?.label ?? "")
        if data.isOpenDoorEnabled {
            statusLabel.text = "Available"
            statusLabel.textColor = Colors.lightGreen
            accessoryType = .disclosureIndicator
        } else {
            statusLabel.text = "Not Available"
            statusLabel.textColor = Colors.lightGray
            accessoryType = .none
        }
    }
}
