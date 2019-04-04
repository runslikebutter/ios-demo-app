//
//  UnitsViewController.swift
//  ButterflyMX Demo
//
//  Created by Taras Markevych on 4/4/19.
//  Copyright © 2019 Taras Markevych. All rights reserved.
//

import UIKit
import BMXCore

class UnitsViewController: UITableViewController {
    var units: [UnitModel]?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 44
        units = BMXUser.shared.getUnits()
        tableView.reloadData()
    }
}

extension UnitsViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return units?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UnitTableViewCell", for: indexPath) as! UnitTableViewCell
        guard let unit = units else { return cell }
        cell.setUnit(unit[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let unit = units else { return }
        let selectedUnit = unit[indexPath.row]
        if selectedUnit.isOpenDoorEnabled {
            let doorViewController = DoorsTableViewController.initViewController()
            doorViewController.panels = BMXUser.shared.getPanels(from: selectedUnit)
            doorViewController.unit = selectedUnit
            navigationController?.pushViewController(doorViewController, animated: true)
        }
    }
}
