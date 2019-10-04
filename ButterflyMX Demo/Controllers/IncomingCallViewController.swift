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
    private var speakerIsEnabled = false
    private var microphoneIsEnabled = true
    var currentCallGuid = ""

    //MARK: - Outlets
    @IBOutlet weak var callTimeLabel: UILabel!
    @IBOutlet weak var callTypeLabel: UILabel!
    @IBOutlet weak var panelNameLabel: UILabel!
    @IBOutlet weak var newCallContainerView: UIView!
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

    @IBAction func acceptCall(_ sender: Any) {
        self.newCallContainerView.isHidden = true
        self.acceptedCallContainerView.isHidden = false
        self.acceptedCallContainerView.alpha = 1.0
        BMXCall.shared.unmuteMic()
        BMXCall.shared.answerCall()
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

    @IBAction func declineCall(_ sender: Any) {
        BMXCall.shared.declineCall()
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func hangUpAction(_ sender: Any) {
        BMXCall.shared.hangupCall()
        self.dismiss(animated: true, completion: nil)
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
        if speakerIsEnabled {
            speakerIsEnabled = false
            sender.setImage(UIImage(named: "button_speaker"), for: .normal)
            DispatchQueue.global(qos: .default).async {
                do {
                    try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.none)
                    DispatchQueue.main.async {
                        sender.isUserInteractionEnabled = true
                    }
                } catch {
                    print("Divert audio to Speaker error: \(error)")
                }
            }
        } else {
            speakerIsEnabled = true
            sender.setImage(UIImage(named: "button_speaker_active"), for: .normal)
            DispatchQueue.global(qos: .default).async {
                do {
                    try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
                    DispatchQueue.main.async {
                        sender.isUserInteractionEnabled = true
                    }
                } catch {
                    print("Divert audio to Speaker error: \(error)")
                }
            }
        }

    }

    //MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        BMXCall.shared.delegate = self
        BMXCall.shared.previewCall(currentCallGuid)
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
        if let call = BMXCall.shared.activeCall?.callDetails {
            if let image = call.mediumUrl {
                let imageData = NSData(contentsOf: URL(string: image)!)
                self.imagePreview.image = UIImage(data: imageData! as Data)
            }
            self.timer = Timer.scheduledTimer(timeInterval: 1, target:self, selector: #selector(updateTime), userInfo: nil, repeats: true)
            self.callTimeLabel.text = "00:00"
            self.callTypeLabel.text = call.getTitle()
            newCallContainerView.isHidden = true
            acceptedCallContainerView.isHidden = true
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
    }

    @objc private func updateTime() {
        self.startTime += 1
        var elapsedTime: TimeInterval = self.startTime
        let minutes = UInt8(self.startTime / 60.0)
        elapsedTime -= (TimeInterval(minutes) * 60)
        let seconds = UInt8(elapsedTime)
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        self.callTimeLabel.text = "\(strMinutes):\(strSeconds)"
    }
    
    private func getVideoSize(basedOnOriginalSize size: CGSize, forFullscreen: Bool) -> CGSize {
        let k = forFullscreen ? videoView.bounds.size.height / size.height
            : videoView.bounds.size.width / size.width
        return CGSize(width: size.width * k, height: size.height * k)
    }

    func setIncomingVideo( _ video: UIView) {
        self.incomingView = video
        video.bounds.size = self.getVideoSize(basedOnOriginalSize: video.bounds.size, forFullscreen: true)
        video.center = self.videoView.center
        video.contentMode = .scaleAspectFill
        video.clipsToBounds = true
        self.imagePreview.isHidden = true
        self.newCallContainerView.isHidden = false
        self.spinner.stopAnimating()
        self.videoView.addSubview(video)
    }
}


extension IncomingCallViewController: BMXCallDelegate {

    func outgoingVideoStarted(video: UIView) -> CGSize? {
        self.selfVideoView.addSubview(video)
        return self.selfVideoView.bounds.size
    }

    func incomingVideoStarted(video: UIView) {
        self.setIncomingVideo(video)
    }

    func callEnded(_ call: CallStatus) {
        self.dismiss(animated: true, completion: nil)
    }
}
