//
//  NotificationService.swift
//  ButterflyMX Demo
//
//  Created by Taras Markevych on 1/17/19.
//  Copyright © 2019 Taras Markevych. All rights reserved.
//

import UIKit
import UserNotifications
import BMXCall
import BMXCore
import PushKit

class NotificationService: NSObject {

    static let shared = NotificationService()
    private var notificationId = 0
    var pushkitToken: Data?
    
    func setupLocalNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        let acceptCallAction = UNNotificationAction(identifier: "accept_call", title: "Accept call", options: [])
        let categoryIncomingCall = UNNotificationCategory(identifier: "IncomingCallCategory",
                                                          actions: [ acceptCallAction ],
                                                          intentIdentifiers: [], options: [])
        notificationCenter.setNotificationCategories([categoryIncomingCall])
        notificationCenter.delegate = self
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if didAllow {
                print("User allowed notifications")
            }
        }
    }
    
    func setupVoipPush() {
        let mainQueue = DispatchQueue.main
        let voipRegistry = PKPushRegistry(queue: mainQueue)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]
    }

    func createLocalNotification(fromCall: Call, with body: String) {
        let content = UNMutableNotificationContent()
        guard let guid = fromCall.guid else {
            print("No call guid")
            return
        }
        content.title = fromCall.panelName ?? "Front door"
        content.body = body
        content.categoryIdentifier = "IncomingCallCategory"
        content.userInfo = [
            "guid" : guid
        ]
        
        if let visitorImageUrl = fromCall.mediumUrl {
            let imageData = NSData(contentsOf: URL(string: visitorImageUrl)!)
            if let data = imageData {
                content.attachments = [UNNotificationAttachment.create(imageFileIdentifier: "\(guid).png", data: data, options: nil)!]
            }
        }

        self.notificationId += 1
        print("Notification: incoming_call_\(fromCall.guid ?? "n/a")_\(self.notificationId)")

        let req = UNNotificationRequest(identifier: "incoming_call_\(fromCall.guid ?? "n/a")_\(self.notificationId)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    func removeLocalNotifications(_ identifiers: [String] = []) {
        self.notificationId = 0
        if identifiers.isEmpty {
            print("***** Remove ALL local notifications *****")
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        } else {
            print("***** Remove local notifications: \(identifiers) *****")
            UNUserNotificationCenter.current().getDeliveredNotifications(completionHandler: { notifications in
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
            })
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { notifications in
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            })
        }
    }
}


extension NotificationService: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            print("Dismiss Action")
        case UNNotificationDefaultActionIdentifier:
            if response.notification.request.content.categoryIdentifier == "IncomingCallCategory" {
                if response.notification.request.content.categoryIdentifier == "IncomingCallCategory", let guid = response.notification.request.content.userInfo["guid"] as? String {
                    if let topViewController = UIApplication.topViewController() {
                        let incomingViewController = IncomingCallViewController.initViewController()
                        incomingViewController.currentCallGuid = guid
                        topViewController.present(incomingViewController, animated: true)
                    }
                }
            }
        default:
            print("Default action")
        }
        completionHandler()
    }
}

extension NotificationService: PKPushRegistryDelegate {
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if BMXCore.shared.isUserLoggedIn {
            pushkitToken = pushCredentials.token
            BMXCore.shared.registerPushKitToken(pushCredentials.token)
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        BMXCall.shared.processCall(payload: payload)
    }
}

