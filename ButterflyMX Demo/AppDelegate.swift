//
//  AppDelegate.swift
//  BMX API Client
//
//  Created by Taras Markevych on 11/13/18.
//  Copyright © 2018 Taras Markevych. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let stb = UIStoryboard(name: "Main", bundle: nil)
        if UserDefaults.standard.isLoggedIn() {
            let mainViewController = stb.instantiateViewController(withIdentifier: "MainTabController")
            window!.rootViewController = mainViewController
        } else {
            let loginViewController = stb.instantiateViewController(withIdentifier: "LoginViewController")
            window!.rootViewController = loginViewController
        }
        window!.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {

    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
}

