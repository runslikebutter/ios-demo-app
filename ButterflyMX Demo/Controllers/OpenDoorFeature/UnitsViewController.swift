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
    var tenants: [TenantModel]?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 44
        tenants = BMXUser.shared.getTenants()        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
}

extension UnitsViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tenants?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UnitTableViewCell", for: indexPath) as! UnitTableViewCell
        guard let tenants = tenants else { return cell }
        cell.setTenant(tenants[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tenants = tenants else { return }
        let selectedTenant = tenants[indexPath.row]
        if selectedTenant.isOpenDoorEnabled {
            let doorViewController = DoorsTableViewController.initViewController()
            doorViewController.devices = BMXUser.shared.getDevices(from: selectedTenant)
            doorViewController.tenant = selectedTenant
            navigationController?.pushViewController(doorViewController, animated: true)
        }
    }
}
