//
//  NotificationService.swift
//  ButterflyMX Demo
//
//  Created by Taras Markevych on 1/17/19.
//  Copyright © 2019 Taras Markevych. All rights reserved.
//

import UIKit
import BMXCall
import BMXCore
import PushKit
import CallKit
import AVFoundation

class CallsService: NSObject {
    
    static let shared = CallsService()
    
    var pushkitToken: Data?
    
    private(set) var provider: CXProvider
    private var callGuid = ""
    private var incomingViewController: IncomingCallViewController?

    private override init() {
       provider = CXProvider(configuration: type(of: self).providerConfiguration)
       super.init()
       provider.setDelegate(self, queue: nil)
    }

    private var callController = CXCallController()

    func endCurrentCallKitCall() {
        let endCallAction = CXEndCallAction(call: UUID(uuidString: callGuid)!)
        let transaction = CXTransaction(action: endCallAction)
        callGuid = ""
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
    
    static var providerConfiguration: CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(localizedName: "ButterflyMXDemo")
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = 1
        providerConfiguration.supportsVideo = true
        providerConfiguration.supportedHandleTypes = [.generic]
        return providerConfiguration
    }

    func setupVoipPush() {
        let mainQueue = DispatchQueue.main
        let voipRegistry = PKPushRegistry(queue: mainQueue)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [.voIP]
    }

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat)
            try session.overrideOutputAudioPort(.speaker)
            try session.setActive(true)
        } catch {
            print("Override audio to Speaker error: \(error)")
        }
    }

}

extension CallsService: PKPushRegistryDelegate, CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        BMXCall.shared.endCall()
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if BMXCore.shared.isUserLoggedIn {
            pushkitToken = pushCredentials.token
            BMXCore.shared.registerPushKitToken(pushCredentials.token)
        }
    }

    private func reportFailedCall(reason: CXCallEndedReason) {
        self.provider.reportCall(with: UUID(uuidString: self.callGuid)!, endedAt: Date(), reason: reason)
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: "Test")
        update.localizedCallerName = "Initializing..."
        update.supportsGrouping = false
        update.supportsHolding = false
        update.supportsUngrouping = false
        update.hasVideo = true

        guard let guid = payload.dictionaryPayload["guid"] as? String, callGuid != guid else {
            // It's the same call or guid is missing, ignore it
            return
        }

        callGuid = guid

        // Audio session should be configured before reporting new incoming call
        setupAudioSession()

        // Report new incoming call to system
        provider.reportNewIncomingCall(with: UUID(uuidString: guid)!, update: update) { error in
            if let _ = error {
                self.reportFailedCall(reason: .failed)
                return
            }

            // Start processing the call by ButterflyMX SDK
            BMXCall.shared.processCall(guid: guid) { result in
                switch result {
                case .success(let call):

                    // Update info about call on call kit
                    let update = CXCallUpdate()
                    if let panelName = call.callDetails?.panelName {
                        update.localizedCallerName = panelName
                    }
                    self.provider.reportCall(with: UUID(uuidString: guid)!, updated: update)

                    // Present the custom incoming view controller
                    DispatchQueue.main.async {
                        self.incomingViewController = IncomingCallViewController.initViewController()
                        if let topViewController = UIApplication.topViewController(), let vc = self.incomingViewController {
                            topViewController.present(vc, animated: true)
                        }
                    }
                case .error(_):
                    self.reportFailedCall(reason: .failed)
                }

            }
        }
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        BMXCall.shared.answerCall()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        BMXCall.shared.endCall()

        incomingViewController?.dismiss(animated: true, completion: nil)
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        if action.isMuted {
            BMXCall.shared.muteMic()
        } else {
            BMXCall.shared.unmuteMic()
        }

        action.fulfill()
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        BMXCall.shared.connectSoundDevice()
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        BMXCall.shared.disconnectSoundDevice()
    }
}

