//
//  AppDelegate.swift
//  BMX API Client
//
//  Created by Taras Markevych on 11/13/18.
//  Copyright © 2018 Taras Markevych. All rights reserved.
//

import UIKit
import BMXCall
import BMXCore
import UserNotifications
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let stb = UIStoryboard(name: "Main", bundle: nil)
        if BMXCoreKit.shared.isUserLoggedIn {
            var env = BMXEnvironment(backendEnvironment: .development)
            switch UserDefaults.standard.string(forKey: "environment") {
                case "sandbox":
                    env = BMXEnvironment(backendEnvironment: .sandbox)
                case "production":
                    env = BMXEnvironment(backendEnvironment: .production)
                default:
                    break
            }
            BMXCoreKit.shared.configure(withEnvironment: env)
            let mainViewController = stb.instantiateViewController(withIdentifier: "MainTabController")
            window!.rootViewController = mainViewController
        } else {
            let loginViewController = stb.instantiateViewController(withIdentifier: "LoginViewController")
            window!.rootViewController = loginViewController
        }
        
        BMXCoreKit.shared.delegate = self

        CallsService.shared.setupVoipPush()
        requestAccessMicCamera(callback: { status in
            print("User media permission status \(status.rawValue)")
        })
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
         if (url.host == "test") {
             BMXCoreKit.shared.handle(url: url)
         }
       return true
     }

    func requestAccessMicCamera(callback: @escaping (_ status: AVAuthorizationStatus) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio, completionHandler: { granted in
            if granted {
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                    if granted {
                        callback(.authorized)
                    } else {
                        callback(.notDetermined)
                    }
                })
            } else {
                callback(.notDetermined)
            }
        })
        return
    }

    func applicationWillResignActive(_ application: UIApplication) {

    }

    func applicationDidEnterBackground(_ application: UIApplication) {
       
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
}

extension AppDelegate: BMXCoreDelegate {
    func didUpdate(accessToken: String, refreshToken: String) {
        print(accessToken, refreshToken)
    }
    
    func logging(_ data: String) {
        print("BMXSDK Log: \(data)")
    }
}
