//
//  calbrateGlassViewController.swift
//  Pupilware
//
//  Created by Xinyi Ding on 8/23/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

import Foundation
import UIKit


class CalibrateGlassViewController: UIViewController, GlassDelegate{

    let model = DataModel.sharedInstance
    let tobiiGlass = TobiiGlass.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        self.model.glassDelegate = self
        self.title = "Calibrate Glass"
        // Do any additional setup after loading the view, typically from a nib.
        
        let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 5 * Int64(NSEC_PER_SEC))
        dispatch_after(time, dispatch_get_main_queue()) {
            //put your code which should be executed with a delay here
            
            //self.model.glassDelegate?.finishGlassCalibration()
            self.finishGlassCalibration()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func finishGlassCalibration() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}