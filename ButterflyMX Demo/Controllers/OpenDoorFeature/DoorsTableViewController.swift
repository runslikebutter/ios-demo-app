//
//  DoorsTableViewController.swift
//  ButterflyMX Demo
//
//  Created by Taras Markevych on 4/9/19.
//  Copyright © 2019 Taras Markevych. All rights reserved.
//

import UIKit
import BMXCore

class DoorsTableViewController: UITableViewController {
    var panels: [PanelModel]?
    var tenant: TenantModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 44
        title = "Select Panel"
    }

    static func initViewController() -> DoorsTableViewController {
        let stbIncomingCall = UIStoryboard(name: "Main", bundle: nil)
        guard let doorsViewController = stbIncomingCall.instantiateViewController(withIdentifier: "DoorsTableViewController") as? DoorsTableViewController else {
            fatalError("No doors view controller init")
        }
        return doorsViewController
    }
}

extension DoorsTableViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return panels?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DoorTableViewCell", for: indexPath) as! DoorTableViewCell
        guard let panels = panels else { return cell }
        cell.doorNameLabel.text = panels[indexPath.row].name ?? ""
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let panel = panels, let tenant = tenant else { return }
        let cell = tableView.cellForRow(at: indexPath) as! DoorTableViewCell
        cell.isUserInteractionEnabled = false
        cell.pleaseWait()
        BMXDoor.shared.openDoor(panel: panel[indexPath.row], tenant: tenant, completion: { result in
            switch result {
            case .success():
                cell.completeWith("Success!", color: Colors.lightGreen)
                tableView.deselectRow(at: indexPath, animated: true)
            case .failure(let error):
                cell.completeWith("Error", color: Colors.lightGray)
                tableView.deselectRow(at: indexPath, animated: true)
                print("Error: \(error)")
            }
            cell.isUserInteractionEnabled = true
        })
    }
}
