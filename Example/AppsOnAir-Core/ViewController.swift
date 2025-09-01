//
//  ViewController.swift
//  AppsOnAir-Core
//
//  Created by 164989979 on 08/29/2024.
//  Copyright (c) 2024 164989979. All rights reserved.
//

import UIKit
import AppsOnAir_Core

class ViewController: UIViewController {
    //MARK: - Declarations
    let appsonAirCoreService = AppsOnAirCoreServices()
    
    //MARK: - UI Elements
    private let getAppIdButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Get App ID", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let getDeviceInfoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Get Device Info", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    //MARK: - View Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // help to initialize common services
        appsonAirCoreService.initialize()
        
        //help to testing network listener
        appsonAirCoreService.networkStatusListenerHandler { isConnected in
            print("Network Connected: \(isConnected)")
        }
        
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(getAppIdButton)
        view.addSubview(getDeviceInfoButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            getAppIdButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            getAppIdButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            getAppIdButton.widthAnchor.constraint(equalToConstant: 200),
            getAppIdButton.heightAnchor.constraint(equalToConstant: 50),
            
            getDeviceInfoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            getDeviceInfoButton.topAnchor.constraint(equalTo: getAppIdButton.bottomAnchor, constant: 20),
            getDeviceInfoButton.widthAnchor.constraint(equalToConstant: 200),
            getDeviceInfoButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        // Actions
        getAppIdButton.addTarget(self, action: #selector(getAppIdTapped), for: .touchUpInside)
        getDeviceInfoButton.addTarget(self, action: #selector(getDeviceInfoTapped), for: .touchUpInside)
    }
    
    //MARK: - Button Actions
    @objc private func getAppIdTapped() {
        let appId = appsonAirCoreService.appId
        showAlert(title: "App ID", message: "\(appId)")
    }
    
    @objc private func getDeviceInfoTapped() {
        appsonAirCoreService.getDeviceInfo { deviceInfo in
            DispatchQueue.main.async {
                self.showAlert(title: "Device Info", message: "\(deviceInfo)")
            }
        }
    }
    
    //MARK: - Helper
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
