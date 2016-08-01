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

    let sT = SyncTobbiGlass()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sT.sendPacket("blabla")
    }
}

