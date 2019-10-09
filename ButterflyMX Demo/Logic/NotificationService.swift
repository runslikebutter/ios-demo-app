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

class NotificationService: NSObject {
    
    static let shared = NotificationService()
    
    var pushkitToken: Data?
    
    private(set) var provider: CXProvider
    private var callGuid = ""
    private var isAnsewred = false

    private override init() {
       provider = CXProvider(configuration: type(of: self).providerConfiguration)
       super.init()
       provider.setDelegate(self, queue: nil)
    }

    private var callController = CXCallController()

    func endCurrentCall() {
        let endCallAction = CXEndCallAction(call: UUID(uuidString: callGuid)!)
        let transaction = CXTransaction(action: endCallAction)
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

}

extension NotificationService: PKPushRegistryDelegate, CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        print("provider reset")
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if BMXCore.shared.isUserLoggedIn {
            pushkitToken = pushCredentials.token
            BMXCore.shared.registerPushKitToken(pushCredentials.token)
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: "Test")
        update.supportsGrouping = false
        update.supportsHolding = false
        update.supportsUngrouping = false
        update.hasVideo = true
        guard let guid = payload.dictionaryPayload["guid"] as? String else { return }

        if callGuid == guid {
            print("It's the same call, ignore it")
            return
        } else {
            callGuid = guid

            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playAndRecord, mode: .voiceChat)
                try session.overrideOutputAudioPort(.speaker)
                try session.setActive(true)
            } catch {
                print("Override audio to Speaker error: \(error)")
            }
            
            reportNewIncomingCall(with: UUID(uuidString: callGuid)!, update: update, completion: { (error) in
                if let error = error {
                    let reason = CXCallEndedReason(rawValue: 0)
                    self.provider.reportCall(with: UUID(uuidString: self.callGuid)!, endedAt: Date(), reason: reason!)
                    print("Incoming CallKit error: \(String(describing: error.localizedDescription))")
                }

                BMXCall.shared.processCall(payload: payload)
                DispatchQueue.main.async {
                    if let topViewController = UIApplication.topViewController() {
                        let incomingViewController = IncomingCallViewController.initViewController()
                        incomingViewController.currentCallGuid = guid
                        topViewController.present(incomingViewController, animated: true)
                    }
                }
            })
        }
    }
    
    func reportNewIncomingCall(with UUID: UUID, update: CXCallUpdate, completion: @escaping (Error?) -> Void) {
        provider.reportNewIncomingCall(with: UUID, update: update) { error in
            completion(error)
        }
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        BMXCall.shared.connectSoundDevice()
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        BMXCall.shared.disconnectSoundDevice()
    }
}

