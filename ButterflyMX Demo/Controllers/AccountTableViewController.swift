//
//  AccountTableViewController.swift
//  
//
//  Created by Taras Markevych on 1/21/19.
//

import UIKit
import BMXCore
import SVProgressHUD

class AccountTableViewController: UITableViewController {
    private var currentUser: UserModel?

    @IBOutlet weak var userAvatar: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    
    private var currentCallNotificationType: CallNotificationType = .videoCall
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        SVProgressHUD.setDefaultStyle(.light)
        getUserInfo()
        currentCallNotificationType = CallNotificationTypeManager.shared.getCurrentCallNotificationType()
    }

    func getUserInfo() {
        self.currentUser = BMXUser.shared.getUser()
        guard let user = self.currentUser else { return }
        if let avatarArray = user.avatars, let avatarUrl = avatarArray["medium_url"] as? String {
                userAvatar.loadImageUsingCache(withUrl: avatarUrl)
        }
        userNameLabel.text = user.name ?? "N/a"
        emailLabel.text = user.email ?? "N/a"
        phoneNumberLabel.text = user.phoneNumber ?? "N/a"
        unitLabel.text = ""
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == currentCallNotificationType.rawValue {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            guard let indexPaths = tableView.indexPathsForVisibleRows else {
                return
            }
            
            let cell = tableView.cellForRow(at: indexPath)
            
            for index in indexPaths {
                if index == indexPath {
                    currentCallNotificationType = CallNotificationType(rawValue: indexPath.row)!
                    cell?.accessoryType = .checkmark
                    saveSelectedCallNotificationType(indexPath.row)

                } else {
                    cell?.accessoryType = .none
                }
            }
            tableView.reloadData()
        } else if indexPath.section == 2 {
            logout()
        }
    }
    
    private func logout() {
        SVProgressHUD.show()
        
        let tenants = BMXUser.shared.getTenants()
        
        let dispatchGroup = DispatchGroup()
        
        for tenant in tenants {
            let key = "webhook-\(tenant.id)"
            if let webhookId = UserDefaults.standard.string(forKey: key) {
                dispatchGroup.enter()
                
                BMXCoreKit.shared.unregisterWebhook(withTenantId: tenant.id, webhookId: webhookId) { result in
                    switch result {
                    case .success:
                        print("remove webhook for key: \(key)")
                        UserDefaults.standard.removeObject(forKey: key)
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                    
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            print("Finished all requests.")
            
            BMXCoreKit.shared.logoutUser()
            SVProgressHUD.dismiss()
            
            let stb = UIStoryboard(name: "Main", bundle: nil)
            let loginViewController = stb.instantiateViewController(withIdentifier: "LoginViewController")
            loginViewController.modalPresentationStyle = .fullScreen
            self.present(loginViewController, animated: true, completion: nil)
        }
    }
    
    private func saveSelectedCallNotificationType(_ selectedCallNotificationType: Int) {
        guard let callNotificationType = CallNotificationType(rawValue: selectedCallNotificationType) else {
            return
        }
        
        CallNotificationTypeManager.shared.saveSelectedCallNotificationType(callNotificationType)
    }
}
