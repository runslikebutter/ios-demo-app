//
//  CallStatusHandler.swift
//  ButterflyMX Demo
//
//  Created by Yingtao Guo on 10/20/21.
//  Copyright © 2021 Taras Markevych. All rights reserved.
//

import Foundation
import BMXCall

class CallStatusHandler: BMXCall.CallStatusDelegate {
    weak var incomingCallViewController: IncomingCallViewController?
    
    func handleCallConnected() {
        incomingCallViewController?.handleCallConnected()
    }
        
    func handleCallAccepted(from call: Call, usingCallKit: Bool) {
        incomingCallViewController?.handleCallAccepted(from: call, usingCallKit: usingCallKit)
    }
    
    func callCanceled(callId: String, reason: CallCancelReason, usingCallKit: Bool) {
        if usingCallKit {
            CallsService.shared.endCurrentCallKitCall()
        }
        
        dismissIncomingCall()
        print("The call (id: \(callId)) is canceld. The reason is \(reason)")
    }
    
    func callEnded(callId: String, reason: CallEndReason, usingCallKit: Bool) {
        if usingCallKit {
            CallsService.shared.endCurrentCallKitCall()
        }

        dismissIncomingCall()
        print("The call (id: \(callId)) is ended. The reason is \(reason)")
    }
    
    private func dismissIncomingCall() {
        CallsService.shared.window?.rootViewController?.dismiss(animated: true)
    }
}
