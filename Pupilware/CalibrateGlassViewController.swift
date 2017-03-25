//
//  calbrateGlassViewController.swift
//  Pupilware
//
//  Created by Xinyi Ding on 8/23/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

import Foundation
import UIKit


class CalibrateGlassViewController: UIViewController, GlassDelegate{

    let model = DataModel.sharedInstance
    let tobiiGlass = TobiiGlass.sharedInstance
    let TIME_DELAY: Int64 = 2
    let TIME_CALIBRATE: Int64 = 3

    override func viewDidLoad() {
        super.viewDidLoad()
        self.model.glassDelegate = self
        self.title = "Calibrate Glass"
        
        // Do any additional setup after loading the view, typically from a nib.
        
        let timeDelay = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), TIME_DELAY * Int64(NSEC_PER_SEC))
        dispatch_after(timeDelay, dispatch_get_main_queue()) {
            self.startCalibration()
        }
        
        let timeCalibrate = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), TIME_CALIBRATE * Int64(NSEC_PER_SEC))
        dispatch_after(timeCalibrate, dispatch_get_main_queue()) {
            self.checkCalibration()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startCalibration() {
        tobiiGlass.createAndStartCalibration(model.tobiiProject, participantId: model.tobiiCurrentParticipant)
    }
    
    func checkCalibration() {
        var message = "Calibration successful!"
        while (true) {
            tobiiGlass.checkCalibration(model.tobiiCurrentCalibration)
            sleep(1)
            if (model.tobiiCurrentCalibrationState == "calibrated" ||  model.tobiiCurrentCalibrationState == "failed" ) {
                break
            }
        }
        if model.tobiiCurrentCalibrationState != "calibrated" {
            message = "Calibration failed! Please recalibrate"
        }
        let alertController = UIAlertController(title: "Calibration", message:
            message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: {
            action -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)}))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func finishGlassCalibration() {
       
    }
}