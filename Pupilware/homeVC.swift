//
//  ViewController.swift
//  Pupilware
//
//  Created by Raymond Martin on 1/27/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

import UIKit

class homeVC: UITabBarController {
    let model = DataModel.sharedInstance

    let tobiiGlass = TobiiGlass(host: "192.168.71.50", port: 49152)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tobiiGlass.startConnect()
    }
}

