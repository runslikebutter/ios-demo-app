//
//  IncomingCallViewController.swift
//  ButterflyMX Demo
//
//  Created by Taras Markevych on 1/17/19.
//  Copyright © 2019 Taras Markevych. All rights reserved.
//

import UIKit
import AVFoundation
import BMXCall
import BMXCore

class IncomingCallViewController: UIViewController {
    fileprivate var cameraIsEnabled = false
    fileprivate var startTime = 0.0
    fileprivate var previewTime = 0.0
    fileprivate var timer: Timer?
    private var speakerIsEnabled = true
    private var microphoneIsEnabled = true

    //MARK: - Outlets
    @IBOutlet weak var callTimeLabel: UILabel!
    @IBOutlet weak var callTypeLabel: UILabel!
    @IBOutlet weak var panelNameLabel: UILabel!
    @IBOutlet weak var acceptedCallContainerView: UIView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var selfVideoView: UIView!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var fullScreenButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var speakerButton: UIButton!
    private var incomingView: UIView?

    @IBAction func fullScreenPressed(_ sender: UIButton) {
        if let video = incomingView {
            let fullscreen = video.bounds.size.width <= videoView.bounds.size.width
            video.bounds.size = getVideoSize(basedOnOriginalSize: video.bounds.size, forFullscreen: fullscreen)
            imagePreview.contentMode = video.contentMode
        } else {
            imagePreview.contentMode = imagePreview.contentMode == .scaleAspectFill ? .scaleAspectFit : .scaleAspectFill
        }
    }

    @IBAction func micAction(_ sender: UIButton) {
        if microphoneIsEnabled {
            microphoneIsEnabled = false
            BMXCallKit.shared.muteMic()
            print("mute mic")
        } else {
            microphoneIsEnabled = true
            BMXCallKit.shared.unmuteMic()
            print("unmute mic")
        }
    }

    @IBAction func hangUpAction(_ sender: Any) {
        CallsService.shared.endCurrntCall()
    }

    @IBAction func openDoorAction(_ sender: Any) {
        BMXCallKit.shared.openDoor() { result in
            if result {
                self.alert(message: "Door is open!")
            } else {
                self.alert(message: "Failed to open the door!")
            }
        }
    }

    @IBAction func cameraAction(_ sender: UIButton) {
        if self.cameraIsEnabled {
            self.selfVideoView.isHidden = true
            self.cameraIsEnabled = false
            BMXCallKit.shared.hideOutgoingVideo()
        } else {
            self.selfVideoView.isHidden = false
            self.cameraIsEnabled = true
            BMXCallKit.shared.showOutgoingVideo()
        }
    }

    @IBAction func speakerAction(_ sender: UIButton) {
        if speakerIsEnabled {
            speakerIsEnabled = false
            BMXCallKit.shared.turnOffSpeaker()
        } else {
            speakerIsEnabled = true
            BMXCallKit.shared.turnOnSpeaker()
        }
    }

    //MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        fullScreenButton.isHidden = true
    }

    static func initViewController() -> IncomingCallViewController {
        let stbIncomingCall = UIStoryboard(name: "Main", bundle: nil)
        guard let incomingCallViewController = stbIncomingCall.instantiateViewController(withIdentifier: "IncomingCallViewController") as? IncomingCallViewController else {
            fatalError("No Incoming init")
        }
        return incomingCallViewController
    }
    
    private func setupUIData() {
        if speakerIsEnabled {
            speakerButton.setImage(UIImage(named: "button_speaker_active"), for: .normal)
        }

        guard let callAttributes = BMXCallKit.shared.activeCall?.attributes else { return }

        if let image = callAttributes.mediumUrl {
            let imageData = NSData(contentsOf: URL(string: image)!)
            self.imagePreview.image = UIImage(data: imageData! as Data)
        }
                
        timer = Timer.scheduledTimer(timeInterval: 1, target:self, selector: #selector(updateTime), userInfo: nil, repeats: true)

        callTimeLabel.text = "00:00"
        callTypeLabel.text = callAttributes.getTitle()
        panelNameLabel.text = callAttributes.panelName
        blurView.addBlurView()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            UIView.animate(withDuration: 1, delay: 0.5, options: .curveEaseOut, animations: {
                self.blurView.alpha = 0.0
            }, completion: { _ in
                self.blurView.removeFromSuperview()
            })
        }
    }

    @objc private func updateTime() {
        startTime += 1
        var elapsedTime: TimeInterval = self.startTime
        let minutes = UInt8(self.startTime / 60.0)
        elapsedTime -= (TimeInterval(minutes) * 60)
        let seconds = UInt8(elapsedTime)
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        callTimeLabel.text = "\(strMinutes):\(strSeconds)"
    }
    
    private func getVideoSize(basedOnOriginalSize size: CGSize, forFullscreen: Bool) -> CGSize {
        let k = forFullscreen ? videoView.bounds.size.height / size.height
            : videoView.bounds.size.width / size.width
        return CGSize(width: size.width * k, height: size.height * k)
    }
}

extension IncomingCallViewController {
    func updateSpeakerControlStatus(enabled: Bool) {
        speakerButton.setImage(UIImage(named: enabled ? "button_speaker_active" : "button_speaker"), for: .normal)
    }
    
    func updateMicrophoneControlStatus(enabled: Bool) {
        micButton.setImage(UIImage(named: enabled ? "button_mute" : "button_mute_active"), for: .normal)
    }
    
    func updateCameraControlStatus(enabled: Bool) {
        cameraButton.setImage(UIImage(named: enabled ? "button_camera_active" : "button_camera"), for: .normal)
    }

    func setupWaitingForAnsweringCallUI() {
        setupUIData()
    }
    
    func getInputVideoViewSize() -> CGSize {
        return view?.bounds.size ?? .zero
    }
    
    func getOutputVideoViewSize() -> CGSize {
        return selfVideoView.bounds.size
    }
    
    func displayIncomingVideo(from view: UIView) {
        incomingView = view
        view.bounds.size = getVideoSize(basedOnOriginalSize: view.bounds.size, forFullscreen: true)
        view.center = videoView.center
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
                
        imagePreview.isHidden = true
        videoView.addSubview(view)
    }
    
    func displayOutgoingVideo(from view: UIView) {
        selfVideoView.addSubview(view)
    }
        
    func handleCallConnected() {
        spinner.stopAnimating()
        fullScreenButton.isHidden = false
        acceptedCallContainerView.isHidden = false
    }
    
    func handleCallAccepted(from call: Call, usingCallKit: Bool) {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 1, target:self, selector: #selector(self.updateTime), userInfo: nil, repeats: true)
    }
}
