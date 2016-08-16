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

    let tobiiGlass = TobiiGlass.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tobiiGlass.startConnect()
        tobiiGlass.createProject()
    }
}

