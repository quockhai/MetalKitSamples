//
//  ViewController.swift
//  MetalDevice
//
//  Created by quockhai on 2019/3/5.
//  Copyright © 2019 Polymath. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    
    @IBOutlet weak var deviceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let device = MTLCreateSystemDefaultDevice() {
            self.deviceLabel.text = "GPU name:\n\(device.name)"
        } else {
            self.deviceLabel.text = "Your device is not supported Metal 🤪"
        }
        
//        self.getDefaultDeviceInfor()
    }

//    func getDefaultDeviceInfor() {
//        let device = MTLCreateSystemDefaultDevice()
//
//        print("GPU name: \(device?.name ?? "")")
//    }
    
}

