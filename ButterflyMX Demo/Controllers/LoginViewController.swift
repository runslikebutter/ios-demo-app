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
import SafariServices

class LoginViewController: UITableViewController {

    @IBOutlet weak var singInButton: UIButton!
    @IBOutlet weak var environmentSegmentControll: UISegmentedControl!
    private var environmentType: BMXBackendEnvironment = .development
    private var authProvider: BMXAuthProvider!
    
    @IBAction func environmentAction(_ sender: Any) {
        switch environmentSegmentControll.selectedSegmentIndex {
        case 0:
            UserDefaults.standard.set("development", forKey: "environment")
            environmentType = .development
        case 1:
            UserDefaults.standard.set("sandbox", forKey: "environment")
            environmentType = .sandbox
        case 2:
            UserDefaults.standard.set("production", forKey: "environment")
            environmentType = .production
        default:
            fatalError("No environment")
        }
        authProvider = getBMXAuthProvider(for: environmentType)
    }
    
    @IBAction func singInAction(_ sender: Any) {
        SVProgressHUD.show()
        let env = BMXEnvironment(backendEnvironment: environmentType)
        BMXCoreKit.shared.configure(withEnvironment: env)
        BMXCoreKit.shared.authorize(withAuthProvider: authProvider, callbackURL: URL(string: "demoapp://test")!, viewController: self) { result in
                 switch result {
                 case .success:
                      let stb = UIStoryboard(name: "Main", bundle: nil)
                      let mainViewController = stb.instantiateViewController(withIdentifier: "MainTabController")
                      mainViewController.modalPresentationStyle = .overFullScreen
                      SVProgressHUD.dismiss()
                      self.present(mainViewController, animated: true, completion: nil)
                 case .failure(let error):
                     print(error)
                     SVProgressHUD.showError(withStatus: error.localizedDescription)
                 }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.set("development", forKey: "environment")
        BMXCoreKit.shared.delegate = self
        BMXCoreKit.shared.authorizationWebViewDelegate = self
        authProvider = getBMXAuthProvider(for: environmentType)
        SVProgressHUD.setDefaultStyle(.light)
    }
    
    private func getBMXAuthProvider(for environment: BMXBackendEnvironment) -> BMXAuthProvider {
        var secret = ""
        var clientId = ""
        switch environment {
        case .development:
            secret = Bundle.main.object(forInfoDictionaryKey: "butterflymxSecretTest") as? String ?? "N/a"
            clientId = Bundle.main.object(forInfoDictionaryKey: "butterflymxClientIdTest") as? String ?? "N/a"
        case .sandbox:
            secret = Bundle.main.object(forInfoDictionaryKey: "butterflymxSecretSandbox") as? String ?? "N/a"
            clientId = Bundle.main.object(forInfoDictionaryKey: "butterflymxClientIdSandbox") as? String ?? "N/a"
        case .production:
            secret = Bundle.main.object(forInfoDictionaryKey: "butterflymxSecretProd") as? String ?? "N/a"
            clientId = Bundle.main.object(forInfoDictionaryKey: "butterflymxClientIdProd") as? String ?? "N/a"
        @unknown default:
            fatalError()
        }
        return BMXAuthProvider(secret: secret, clientID: clientId)
    }
}

extension LoginViewController: BMXCoreDelegate {    
    func logging(_ data: String) {
        print("BMXSDK Log: \(data)")
    }
}

extension LoginViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        SVProgressHUD.dismiss()
    }
}
