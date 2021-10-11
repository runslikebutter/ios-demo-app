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
    var window: UIWindow?
    
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
        provider.reportNewIncomingCall(with: UUID(uuidString: guid)!, update: update) { [weak self] error in
            if let _ = error {
                self?.reportFailedCall(reason: .failed)
                return
            }
                        
            DispatchQueue.main.async {
                self?.incomingViewController = IncomingCallViewController.initViewController()
                
                guard let topViewController = UIApplication.topViewController() ?? CallsService.shared.window?.rootViewController,
                let incomingViewController  = self?.incomingViewController else {
                    BMXCoreKit.shared.log(message: "** Error: Couldn't load top view controller **")
                    return
                }
                            
                topViewController.present(incomingViewController, animated: true) {
                    processCall()
                }
            }
                                                
            func processCall() {
                // Start processing the call by ButterflyMX SDK
                BMXCallKit.shared.processCall(guid: guid,
                                              callType: .callkit,
                                              incomingCallPresenter: self?.incomingViewController) { result in
                    switch result {
                    case .success(let call):
                        // Update info about call on call kit
                        let update = CXCallUpdate()
                        if let panelName = call.attributes?.panelName {
                            update.localizedCallerName = panelName
                        }
                        self?.provider.reportCall(with: UUID(uuidString: guid)!, updated: update)
                    case .failure(let error):
                        print(error.localizedDescription)
                        self?.reportFailedCall(reason: .failed)
                    }

                }
            }
        }
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        BMXCallKit.shared.previewCall(autoAccept: true)
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        BMXCallKit.shared.endCall()

        incomingViewController?.dismiss(animated: true, completion: nil)
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
