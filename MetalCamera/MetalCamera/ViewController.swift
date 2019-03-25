//
//  ViewController.swift
//  MetalCamera
//
//  Created by quockhai on 2019/3/25.
//  Copyright © 2019 Polymath. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var cameraView: UIView!
    var session: MetalCameraSession!
    
    override func loadView() {
        super.loadView()
        
        let cameraView = UIView(frame: .zero)
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(cameraView)
        
        NSLayoutConstraint.activate([
            cameraView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 1.0),
            cameraView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 1.0),
            cameraView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            cameraView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
            ])
        
        self.cameraView = cameraView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureCameraController()
    }

    func configureCameraController() {
        self.session = MetalCameraSession()
        self.session.prepare {(error) in
            if let error = error {
                print(error)
            }
            
            try? self.session.displayPreview(on: self.cameraView)
        }
    }

}

