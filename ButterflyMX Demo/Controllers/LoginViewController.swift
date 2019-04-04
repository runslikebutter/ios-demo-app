//
//  LoginViewController.swift
//  BMX API Client
//
//  Created by Taras Markevych on 11/13/18.
//  Copyright © 2018 Taras Markevych. All rights reserved.
//

import UIKit
import BMXCore
import SVProgressHUD
class LoginViewController: UITableViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var singInButton: UIButton!

    @IBAction func singInAction(_ sender: Any) {
        guard var emailValue = emailTextField.text, let passwordValue = passwordTextField.text else { return }
        SVProgressHUD.show()
        emailValue = emailValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if emailValue.isEmailAddress {
            signIn(email: emailValue, password: passwordValue)
        } else {
            self.alert(message: "Invalid Email", title: "Autorization error")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        BMXCore.shared.delegate = self
        SVProgressHUD.setDefaultStyle(.light)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.emailTextField.becomeFirstResponder()
    }

    private func signIn(email: String, password: String ) {
        BMXCore.shared.loginUser(email: email, password: password, completion: { response in
            switch response {
                case .error(let error):
                    print(error)
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                case .success(let user):
                    print(user)
                    SVProgressHUD.dismiss()
                    let stb = UIStoryboard(name: "Main", bundle: nil)
                    let mainViewController = stb.instantiateViewController(withIdentifier: "MainTabController")
                    self.present(mainViewController, animated: true, completion: nil)
            }
       })
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.emailTextField {
            self.emailTextField.resignFirstResponder()
            self.passwordTextField.becomeFirstResponder()
        }
        if textField == self.passwordTextField {
            self.passwordTextField.resignFirstResponder()
        }
        return true
    }
}

extension LoginViewController: BMXCoreDelegate {
    func logging(_ data: String) {
        print("BMXSDK Log: \(data)")
    }
}
