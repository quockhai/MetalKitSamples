//
//  ViewController.swift
//  MetalMatrix
//
//  Created by quockhai on 2019/3/7.
//  Copyright © 2019 Polymath. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    weak var triangleView: TriangleMetalView!
    weak var statusLabel: UILabel!
    
    override func loadView() {
        super.loadView()
        
        let triangleView = TriangleMetalView(frame: .zero)
        triangleView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(triangleView)
        
        let statusLabel = UILabel(frame: .zero)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            statusLabel.widthAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.9),
            statusLabel.heightAnchor.constraint(equalToConstant: 100.0),
            statusLabel.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor)
            ])
        
        NSLayoutConstraint.activate([
            triangleView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 1.0),
            triangleView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 1.0),
            triangleView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            triangleView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
            ])
        
        self.triangleView = triangleView
        self.statusLabel = statusLabel
    }
    
    func configureSubViews() {
        self.statusLabel.numberOfLines = 0
        self.statusLabel.textAlignment = .center
        self.statusLabel.isHidden = true
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureSubViews()
        
        guard MTLCreateSystemDefaultDevice() != nil else {
            self.statusLabel.isHidden = false
            self.statusLabel.text = " Your device is not supported Metal 🤪"
            return
        }
    }
}

