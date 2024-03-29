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
    var pushNotificationToken: Data?
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
    
    func getPushToken() -> Data? {
        if CallNotificationTypeManager.shared.getCurrentCallNotificationType() == .voip {
            return pushkitToken
        } else {
            return pushNotificationToken
        }
    }
    
    func endCurrentCall() {
        if CallNotificationTypeManager.shared.getCurrentCallNotificationType() == .voip {
            endCurrentCallKitCall()
        } else {
            BMXCallKit.shared.endCall()
        }
    }
    
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

    func requestPushNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .denied:
                BMXCoreKit.shared.log(message: "Notification permission status: denied")
                DispatchQueue.main.async {
                    let settingsUrl = URL(string: UIApplication.openSettingsURLString)
                    if let url = settingsUrl {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            case .notDetermined:
                BMXCoreKit.shared.log(message: "Notification permission status: notDetermined")
                center.requestAuthorization(options:[.alert, .sound, .badge]) { ok, err in
                    if let err = err {
                        BMXCoreKit.shared.log(message: "Not Authorized \(err.localizedDescription)")
                    }
                }
            case .authorized:
                BMXCoreKit.shared.log(message: "Notification permission status: authorized")
            case .provisional:
                BMXCoreKit.shared.log(message: "Notification permission status: Provisional")
            case .ephemeral:
                BMXCoreKit.shared.log(message: "Notification permission status: Ephemeral")
            @unknown default:
                BMXCoreKit.shared.log(message: "Notification permission status: Default")
                break
            }
        }
    }
}

extension CallsService: PKPushRegistryDelegate, CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        BMXCallKit.shared.endCall()
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        pushkitToken = pushCredentials.token

        let token = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(token, forKey: "deviceToken")
        UserDefaults.standard.synchronize()
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
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        handleCallPushNotification(userInfo: userInfo)
    }
    
    private func handleCallPushNotification(userInfo: [AnyHashable: Any]) {
        guard let guid = userInfo["guid"] as? String else {
            return
        }
        
        if callGuid != guid {
            callGuid = guid
            setupAudioSession()
            
            BMXCallKit.shared.processCall(guid: guid,
                                          callType: .notification) { [weak self] _ in
                self?.incomingCallPresenter.presentIncomingCall() {
                    BMXCallKit.shared.previewCall(autoAccept: true)
                    BMXCallKit.shared.turnOnSpeaker()
                }
                self?.callStatusHandler.incomingCallViewController = self?.incomingCallPresenter.incomingCallViewController
            }
        }
    }
}
