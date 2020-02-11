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

    @IBOutlet weak var singInButton: UIButton!

    @IBAction func singInAction(_ sender: Any) {
        let auth = BMXAuthProvider(secret: Bundle.main.object(forInfoDictionaryKey: "butterflymx-SECRET") as? String ?? "N/a",
                                   clientID: Bundle.main.object(forInfoDictionaryKey: "butterflymx-CLIENTID") as? String ?? "N/a")
         BMXCore.shared.authorize(withAuthProvider: auth, callbackURL: URL(string: "demoapp://test")!) { result in
                 switch result {
                 case .success(let _):
                      let stb = UIStoryboard(name: "Main", bundle: nil)
                      let mainViewController = stb.instantiateViewController(withIdentifier: "MainTabController")
                      mainViewController.modalPresentationStyle = .overFullScreen
                      self.present(mainViewController, animated: true, completion: {
                          guard let pushToken = CallsService.shared.pushkitToken else { return }
                          BMXCore.shared.registerPushKitToken(pushToken)
                      })
                 case .error(let error):
                     print(error)
                     SVProgressHUD.showError(withStatus: error.localizedDescription)
                 }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        BMXCore.shared.delegate = self
        SVProgressHUD.setDefaultStyle(.light)
    }
}

extension LoginViewController: BMXCoreDelegate {
    func logging(_ data: String) {
        print("BMXSDK Log: \(data)")
    }
}
