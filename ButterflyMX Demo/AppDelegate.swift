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
        if BMXCore.shared.isUserLoggedIn {
            let mainViewController = stb.instantiateViewController(withIdentifier: "MainTabController")
            window!.rootViewController = mainViewController
        } else {
            let loginViewController = stb.instantiateViewController(withIdentifier: "LoginViewController")
            window!.rootViewController = loginViewController
        }
        let auth = BMXAuthProvider(secret: ProcessInfo.processInfo.environment["SECRET"] ?? "N/a",
                                   clientID: ProcessInfo.processInfo.environment["CLIENTID"] ?? "N/a")
        let env = BMXEnvironment(backendEnvironment: .development)
        BMXCore.shared.configure(withEnvironment: env, andAuthProvider: auth)
        BMXCall.shared.notificationsDelegate = self
        BMXCore.shared.delegate = self

        NotificationService.shared.setupLocalNotifications()
        requestAccessMicCamera(callback: { status in
            print("User media permission status \(status.rawValue)")
        })
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

extension AppDelegate: BMXCallNotificationsDelegate {
    func callCanceled(_ call: Call, reason: CallCancelReason) {
        NotificationService.shared.removeLocalNotifications()
        switch reason {
        case .AnsweredByOthers:
            NotificationService.shared.createLocalNotification(fromCall: call, with: "Call answered on another device")
        default:
            NotificationService.shared.createLocalNotification(fromCall: call, with: "Call missed")
        }
    }

    func callReceived(_ call: Call) {
        NotificationService.shared.createLocalNotification(fromCall: call, with: "You have a \(call.getTitle())")
    }
}

extension AppDelegate: BMXCoreDelegate {
    func logging(_ data: String) {
        print("BMXSDK Log: \(data)")
    }
}
