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
    
    private var previousCallNotificationType: CallNotificationType = .voip
    private var currentCallNotificationType: CallNotificationType = .voip
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        SVProgressHUD.setDefaultStyle(.light)
        getUserInfo()
        previousCallNotificationType = CallNotificationTypeManager.shared.getCurrentCallNotificationType()
        currentCallNotificationType = previousCallNotificationType
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        previousCallNotificationType = currentCallNotificationType
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
            
            if previousCallNotificationType != currentCallNotificationType {
                unregisterWebhooks { [weak self] in
                    SVProgressHUD.dismiss()
                    
                    if self?.currentCallNotificationType == .pushNotification {
                        self?.showRegisterWebhookAlert() {
                            CallsService.shared.requestPushNotificationPermission()
                        }
                    } else {
                        self?.showRegisterWebhookAlert()
                    }
                    
                }
            }
            
        } else if indexPath.section == 2 {
            logout()
        }
    }
    
    private func showRegisterWebhookAlert(completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "Alert", message: "You need to register webhooks again.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            alert.dismiss(animated: true, completion: nil)
            completion?()
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    private func logout() {
        SVProgressHUD.show()
        
        unregisterWebhooks { [weak self] in
            BMXCoreKit.shared.logoutUser()
            SVProgressHUD.dismiss()
            
            let stb = UIStoryboard(name: "Main", bundle: nil)
            let loginViewController = stb.instantiateViewController(withIdentifier: "LoginViewController")
            loginViewController.modalPresentationStyle = .fullScreen
            self?.present(loginViewController, animated: true, completion: nil)
        }
    }
    
    private func unregisterWebhooks(completion: @escaping () -> Void) {
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
            completion()
        }
    }
    
    private func saveSelectedCallNotificationType(_ selectedCallNotificationType: Int) {
        guard let callNotificationType = CallNotificationType(rawValue: selectedCallNotificationType) else {
            return
        }
        
        CallNotificationTypeManager.shared.saveSelectedCallNotificationType(callNotificationType)
    }
}
