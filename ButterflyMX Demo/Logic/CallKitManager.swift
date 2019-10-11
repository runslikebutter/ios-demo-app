//
//  CallKitManager.swift
//  ButterflyMX Demo
//
//  Created by Taras Markevych on 08.10.2019.
//  Copyright © 2019 Taras Markevych. All rights reserved.
//

import UIKit
import CallKit

class CallKitManager {

    private var callController = CXCallController()

    func end(call: UUID) {
        let endCallAction = CXEndCallAction(call: call)
        let transaction = CXTransaction(action: endCallAction)
        print("Call declined")
        requestTransaction(transaction)
    }

    private func requestTransaction(_ transaction: CXTransaction) {
        callController.request(transaction) { error in
            if let error = error {
                print("Error requesting transaction: \(error)")
            } else {
                print("Requested transaction successfully")
            }
        }
    }
}
