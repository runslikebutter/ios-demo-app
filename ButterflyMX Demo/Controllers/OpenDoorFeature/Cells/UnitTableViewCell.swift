//
//  UnitTableViewCell.swift
//  ButterflyMX Demo
//
//  Created by Taras Markevych on 4/4/19.
//  Copyright © 2019 Taras Markevych. All rights reserved.
//

import UIKit
import BMXCore
import SVProgressHUD

class UnitTableViewCell: UITableViewCell {

    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var registerWebhookSwitch: UISwitch!
    
    var tenantModel: TenantModel? = nil

    func setTenant(_ tenantModel: TenantModel) {
        self.tenantModel = tenantModel
        unitLabel.text = "Unit: " + (tenantModel.unit?.label ?? "")
        if tenantModel.isOpenDoorEnabled {
            statusLabel.text = "Available"
            statusLabel.textColor = Colors.lightGreen
            accessoryType = .disclosureIndicator
        } else {
            statusLabel.text = "Not Available"
            statusLabel.textColor = Colors.lightGray
            accessoryType = .none
        }
        
        registerWebhookSwitch.isOn = UserDefaults.standard.string(forKey: "webhook-\(tenantModel.id)") != nil
    }
        
    @IBAction func toggleRegisterWebhook(_ sender: Any) {
        guard let tenantModel = tenantModel  else {
            return
        }
        
        let key = "webhook-\(tenantModel.id)"
        
        if registerWebhookSwitch.isOn {
            guard let deviceToken = UserDefaults.standard.string(forKey: "deviceToken") else {
                return
            }
            
            let ngrokId = "6036eb46088a"
            let webhookUrl = "http://\(ngrokId).ngrok.io/webhook/?token=\(deviceToken)&type=voip"
                        
            SVProgressHUD.show()
            BMXCoreKit.shared.registerWebhook(withTenantId: tenantModel.id, urlString: webhookUrl) { [weak self] result in
                switch result {
                case .success(let webhookId):
                    UserDefaults.standard.set(webhookId, forKey: key)
                    UserDefaults.standard.synchronize()
                case .failure(let error):
                    switch error {
                    case .runtime(let error):
                        print(error.localizedDescription)
                    case .unableToCreateRequest(let message):
                        fallthrough
                    case .unableToProcessResponse(let message):
                        print(message)
                    @unknown default:
                        print("unknown error")
                    }
                    self?.registerWebhookSwitch.isOn = false
                }
                SVProgressHUD.dismiss()
            }
        } else if let webhookId = UserDefaults.standard.string(forKey: key)  {
            SVProgressHUD.show()
            BMXCoreKit.shared.unregisterWebhook(withTenantId: tenantModel.id, webhookId: webhookId) { result in
                switch result {
                case .success:
                    UserDefaults.standard.removeObject(forKey: key)
                case .failure(let error):
                    print(error.localizedDescription)
                }
                SVProgressHUD.dismiss()
            }
        }
    }
}
