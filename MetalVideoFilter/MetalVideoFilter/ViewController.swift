//
//  ViewController.swift
//  MetalVideoFilter
//
//  Created by quockhai on 2019/4/11.
//  Copyright © 2019 Polymath. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    weak var metalView: MetalView!
    weak var statusLabel: UILabel!
    
    weak var slider: UISlider!
    
    let streamURL = URL(string: "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")!
    
    override func loadView() {
        super.loadView()
        
        let metalView = MetalView(frame: .zero)
        metalView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(metalView)
        
        let statusLabel = UILabel(frame: .zero)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(statusLabel)
        
        let slider = UISlider(frame: .zero)
        slider.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(slider)
        
        NSLayoutConstraint.activate([
            statusLabel.widthAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.9),
            statusLabel.heightAnchor.constraint(equalToConstant: 100.0),
            statusLabel.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor)
            ])
        
        NSLayoutConstraint.activate([
            metalView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 1.0),
            metalView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 1.0),
            metalView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            metalView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
            ])

        //slider.heightAnchor.constraint(equalToConstant: 100.0),
        NSLayoutConstraint.activate([
            slider.widthAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.5),
            slider.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            slider.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10.0)
            ])
        
        self.metalView = metalView
        self.statusLabel = statusLabel
        self.slider = slider
    }
    
    func configureSubViews() {
        self.statusLabel.numberOfLines = 0
        self.statusLabel.textAlignment = .center
        self.statusLabel.isHidden = true
        
        self.slider.minimumValue = 0.0
        self.slider.maximumValue = 10.0
        self.slider.value = 1.0
        self.slider.addTarget(self, action: #selector(self.sliderValueChanged(slider:)), for: .valueChanged)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureSubViews()
        
        guard MTLCreateSystemDefaultDevice() != nil else {
            self.statusLabel.isHidden = false
            self.statusLabel.text = " Your device is not supported Metal 🤪"
            return
        }
        
        self.metalView.play(stream: streamURL, withBlur: Double(self.slider.value)) {
            self.metalView.player.isMuted = true
        }
    }
    
    @objc func sliderValueChanged(slider: UISlider) {
        self.metalView.blurRadius = Double(slider.value)
    }
}



