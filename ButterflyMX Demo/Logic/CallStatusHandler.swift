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
    
    func callConnected() {
        incomingCallViewController?.handleCallConnected()
    }
        
    func callAccepted(from call: Call, usingCallKit: Bool) {
        incomingCallViewController?.handleCallAccepted(from: call, usingCallKit: usingCallKit)
    }
    
    func callCanceled(callId: String, reason: CallCancelReason, usingCallKit: Bool) {
        if usingCallKit {
            CallsService.shared.endCurrentCallKitCall()
        }
        
        dismissIncomingCall()
        print("The call (id: \(callId)) is canceld. The reason is \(reason)")
    }
    
    func callEnded(callId: String, usingCallKit: Bool) {
        if usingCallKit {
            CallsService.shared.endCurrentCallKitCall()
        }

        dismissIncomingCall()
        print("The call (id: \(callId)) is ended.")
    }
    
    private func dismissIncomingCall() {
        incomingCallViewController?.dismiss(animated: true)
    }
}
