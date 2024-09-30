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
    
    //MARK: - View Methods
    override func viewDidLoad() {
        super.viewDidLoad()
          // help to initialize common services 
           appsonAirCoreService.initialize()

           //help to testing network listener
        appsonAirCoreService.networkStatusListenerHandler { isConnected in
            //Do here Code of testing network listener
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

