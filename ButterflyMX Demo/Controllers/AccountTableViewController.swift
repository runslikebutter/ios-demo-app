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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        SVProgressHUD.setDefaultStyle(.light)
        getUserInfo()
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 0 {
            SVProgressHUD.show()
            
            APIClient.shared.unRegisterDevice { result in
                switch result {
                case .success:
                    // Will change this line when releasing a new SDK since I removed completion from logoutUser
                    BMXCoreKit.shared.logoutUser{ result in }
                    
                    SVProgressHUD.dismiss()
                    
                    let stb = UIStoryboard(name: "Main", bundle: nil)
                    let loginViewController = stb.instantiateViewController(withIdentifier: "LoginViewController")
                    loginViewController.modalPresentationStyle = .fullScreen
                    self.present(loginViewController, animated: true, completion: nil)
                    
                case .failure(let error):
                    SVProgressHUD.dismiss()
                    self.alert(message: error.localizedDescription)
                }
            }
        }
    }

}
