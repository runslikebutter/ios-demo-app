//
//  CallNotificationTypeManager.swift
//  ButterflyMX Demo
//
//  Created by Yingtao Guo on 11/18/21.
//  Copyright © 2021 Taras Markevych. All rights reserved.
//

import Foundation

enum CallNotificationType: Int {
    case videoCall
    case pushNotification
}

let callNotificationKey = "callNotificationKey"

class CallNotificationTypeManager {
    static let shared = CallNotificationTypeManager()
    
    private init() {}
    
    func saveSelectedCallNotificationType(_ callNotificationType: CallNotificationType) {
        UserDefaults.standard.set(callNotificationType.rawValue, forKey: callNotificationKey)
    }
    
    func getCurrentCallNotificationType() -> CallNotificationType {
        let callNotficationType = UserDefaults.standard.integer(forKey: callNotificationKey)
        print(callNotficationType)
        return CallNotificationType(rawValue: callNotficationType) ?? .videoCall
    }
}
