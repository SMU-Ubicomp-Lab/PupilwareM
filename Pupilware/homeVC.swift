//
//  ViewController.swift
//  Pupilware
//
//  Created by Raymond Martin on 1/27/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

import UIKit

class homeVC: UITabBarController {
    let model = DataModel.sharedInstance

    let tobiiGlass = TobiiGlass.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self,
                       selector: #selector(homeVC.tobiiAlert),
                       name: "SysUnavailable",
                       object: nil)
        
        // TODO : enable it when we need it.
        //tobiiGlass.startConnect()
        //tobiiGlass.createProject()
        
        //let timer = NSTimer.scheduledTimerWithTimeInterval(10.0, target: self, selector: #selector(homeVC.checkSys), userInfo: nil, repeats: true)
    }
    
    func tobiiAlert() {
        let message = "There might be a connection issue with tobii!"
        let alertController = UIAlertController(title: "Tobii Alert!", message:
            message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: {
            action -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)}))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func checkSys() {
        tobiiGlass.checkSystemStatus()
    }
}

