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
    private var incomingCallPresenter = IncomingCallPresenter()
    private var callStatusHandler = CallStatusHandler()
    
    var pushkitToken: Data?
    var window: UIWindow?
    
    private(set) var provider: CXProvider
    private var callGuid = ""
    
    private override init() {
        provider = CXProvider(configuration: type(of: self).providerConfiguration)
        super.init()
        BMXCallKit.shared.incomingCallPresenter = incomingCallPresenter
        BMXCallKit.shared.callStatusDelegate = callStatusHandler
        
        provider.setDelegate(self, queue: nil)
    }

    private var callController = CXCallController()
    
    func endCurrentCallKitCall() {
        guard !callGuid.isEmpty, let callId = UUID(uuidString: callGuid) else {
            return
        }
        
        let endCallAction = CXEndCallAction(call: callId)
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
        BMXCallKit.shared.endCall()
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        pushkitToken = pushCredentials.token
        if BMXCoreKit.shared.isUserLoggedIn {
            let token = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
            
            UserDefaults.standard.set(token, forKey: "deviceToken")
            UserDefaults.standard.synchronize()
        }
    }

    private func reportFailedCall(reason: CXCallEndedReason) {
        self.provider.reportCall(with: UUID(uuidString: self.callGuid)!, endedAt: Date(), reason: reason)
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        guard let guid = payload.dictionaryPayload["guid"] as? String else {
            self.reportFailedCall(reason: .failed)
            return
        }

        if callGuid != guid {
            callGuid = guid
            let update = CXCallUpdate()
            update.remoteHandle = CXHandle(type: .generic, value: "Test")
            update.localizedCallerName = "Initializing..."
            update.supportsGrouping = false
            update.supportsHolding = false
            update.supportsUngrouping = false
            update.hasVideo = true
            
            // Audio session should be configured before reporting new incoming call
            setupAudioSession()

            provider.reportNewIncomingCall(with: UUID(uuidString: guid)!, update: update) { [weak self] error in
                if let _ = error {
                    self?.reportFailedCall(reason: .failed)
                    return
                }

                processCall()
            }
        } else {
            processCall()
        }
        
        func processCall() {
            BMXCallKit.shared.processCall(guid: guid,
                                          callType: .callkit) { result in
                switch result {
                case .success(let call):
                    // Update info about call on call kit
                    let update = CXCallUpdate()
                    if let panelName = call.attributes?.panelName {
                        update.localizedCallerName = panelName
                    }
                    self.provider.reportCall(with: UUID(uuidString: guid)!, updated: update)
                case .failure(let error):
                    print(error.localizedDescription)
                    self.reportFailedCall(reason: .failed)
                }
            }
        }
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        incomingCallPresenter.presentIncomingCall() {
            BMXCallKit.shared.previewCall(autoAccept: true)
            BMXCallKit.shared.turnOnSpeaker()
        }
        callStatusHandler.incomingCallViewController = incomingCallPresenter.incomingCallViewController
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        BMXCallKit.shared.endCall()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        if action.isMuted {
            BMXCallKit.shared.muteMic()
        } else {
            BMXCallKit.shared.unmuteMic()
        }

        action.fulfill()
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        BMXCallKit.shared.connectSoundDevice()
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        BMXCallKit.shared.disconnectSoundDevice()
    }
}

extension CallsService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
    }
}
