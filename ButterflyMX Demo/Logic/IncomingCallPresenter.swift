//
//  IncomingCallPresenter.swift
//  ButterflyMX Demo
//
//  Created by Yingtao Guo on 10/19/21.
//  Copyright © 2021 Taras Markevych. All rights reserved.
//

import Foundation
import BMXCall
import BMXCore

class IncomingCallPresenter: BMXCall.IncomingCallUIInputs {
    var delegate: (IncomingCallUIDataSource & IncomingCallUIDelegate)?
    var incomingCallViewController: IncomingCallViewController?
    
    func presentIncomingCall(completion: (() -> Void)?) {
        guard let topViewController = UIApplication.topViewController() ?? CallsService.shared.window?.rootViewController else {
            BMXCoreKit.shared.log(message: "** Error: Couldn't load top view controller **")
            return
        }
        
        incomingCallViewController = IncomingCallViewController.initViewController()
        incomingCallViewController?.modalPresentationStyle = .fullScreen
        
        guard let incomingCallViewController = incomingCallViewController else {
            return
        }

        topViewController.present(incomingCallViewController, animated: true, completion: completion)
    }
    
    func setupWaitingForAnsweringCallUI() {
        incomingCallViewController?.setupWaitingForAnsweringCallUI()
    }
        
    func getInputVideoViewSize() -> CGSize {
        return incomingCallViewController?.getInputVideoViewSize() ?? .zero
    }
    
    func getOutputVideoViewSize() -> CGSize {
        return incomingCallViewController?.getOutputVideoViewSize() ?? .zero
    }
    
    func displayIncomingVideo(from view: UIView) {
        incomingCallViewController?.displayIncomingVideo(from: view)
    }
    
    func displayOutgoingVideo(from view: UIView) {
        incomingCallViewController?.displayOutgoingVideo(from: view)
    }
    
    func updateSpeakerControlStatus() {
        guard let speakerEnabled = delegate?.speakerEnabled else {
            return
        }
        incomingCallViewController?.updateSpeakerControlStatus(enabled: speakerEnabled)
    }
    
    func updateMicrophoneControlStatus() {
        guard let micEnabled = delegate?.micEnabled else {
            return
        }

        incomingCallViewController?.updateMicrophoneControlStatus(enabled: micEnabled)
    }
    
    func updateCameraControlStatus() {
        guard let cameraEnabled = delegate?.cameraEnabled else {
            return
        }

        incomingCallViewController?.updateCameraControlStatus(enabled: cameraEnabled)
    }
}
