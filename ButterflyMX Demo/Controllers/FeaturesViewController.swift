//
//  FeaturesViewController.swift
//  BMX API Client
//
//  Created by Taras Markevych on 11/13/18.
//  Copyright © 2018 Taras Markevych. All rights reserved.
//

import UIKit
import AVFoundation

class FeaturesViewController: UIViewController {
    //MARK: - Outlets
    @IBOutlet weak var openDoorButton: UIButton!
    @IBAction func openDoorAction(_ sender: Any) {
       self.alert(message: "Not available yet")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

}

