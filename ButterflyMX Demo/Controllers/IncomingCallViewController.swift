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
    var currentCallGuid = ""

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
            sender.setImage(UIImage(named: "button_mute_active"), for: .normal)
            BMXCall.shared.muteMic()
            print("mute mic")
        } else {
            microphoneIsEnabled = true
            sender.setImage(UIImage(named: "button_mute"), for: .normal)
            BMXCall.shared.unmuteMic()
            print("unmute mic")
        }
    }

    @IBAction func hangUpAction(_ sender: Any) {
        BMXCall.shared.endCall()
    }

    @IBAction func openDoorAction(_ sender: Any) {
        BMXCall.shared.openDoor()
        self.alert(message: "Door is open!")
    }

    @IBAction func cameraAction(_ sender: UIButton) {
        if self.cameraIsEnabled {
            sender.setImage(UIImage(named: "button_camera"), for: .normal)
            self.selfVideoView.isHidden = true
            self.cameraIsEnabled = false
            BMXCall.shared.hideOutgoingVideo()
        } else {
            self.selfVideoView.isHidden = false
            self.cameraIsEnabled = true
            BMXCall.shared.showOutgoingVideo()
            sender.setImage(UIImage(named: "button_camera_active"), for: .normal)
        }
    }

    @IBAction func speackerAction(_ sender: UIButton) {
        sender.isUserInteractionEnabled = false
        speakerIsEnabled = !speakerIsEnabled

        sender.setImage(UIImage(named: speakerIsEnabled ? "button_speaker_active" : "button_speaker"), for: .normal)
        DispatchQueue.global(qos: .default).async {
            do {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(self.speakerIsEnabled ? .speaker : .none)
                DispatchQueue.main.async {
                    sender.isUserInteractionEnabled = true
                }
            } catch {
                print("Divert audio to Speaker error: \(error)")
            }
        }
    }

    //MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        BMXCall.shared.delegate = self
        setupUIData()
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

        guard let call = BMXCall.shared.activeCall?.callDetails else { return }

        if let image = call.mediumUrl {
            let imageData = NSData(contentsOf: URL(string: image)!)
            self.imagePreview.image = UIImage(data: imageData! as Data)
        }
        timer = Timer.scheduledTimer(timeInterval: 1, target:self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        callTimeLabel.text = "00:00"
        callTypeLabel.text = call.getTitle()
        panelNameLabel.text = call.panelName
        blurView.addBlurView()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            UIView.animate(withDuration: 1, delay: 0.5, options: .curveEaseOut, animations: {
                self.blurView.alpha = 0.0
            }, completion: { (_) in
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

    func setIncomingVideo( _ video: UIView) {
        incomingView = video
        video.bounds.size = self.getVideoSize(basedOnOriginalSize: video.bounds.size, forFullscreen: true)
        video.center = self.videoView.center
        video.contentMode = .scaleAspectFill
        video.clipsToBounds = true
        imagePreview.isHidden = true
        spinner.stopAnimating()
        videoView.addSubview(video)
    }
}


extension IncomingCallViewController: BMXCallDelegate {

    func outgoingVideoStarted(video: UIView) -> CGSize? {
        selfVideoView.addSubview(video)
        return selfVideoView.bounds.size
    }

    func incomingVideoStarted(video: UIView) {
        setIncomingVideo(video)
        acceptedCallContainerView.isHidden = false
    }

    func callEnded(_ call: CallStatus) {
        DispatchQueue.main.async {
            CallsService.shared.endCurrentCallKitCall()
            self.dismiss(animated: true, completion: nil)
        }
    }

    func callCanceled(_ call: CallStatus, reason: CallCancelReason) {
        DispatchQueue.main.async {
            CallsService.shared.endCurrentCallKitCall()
            self.dismiss(animated: true, completion: nil)
        }
    }
}
