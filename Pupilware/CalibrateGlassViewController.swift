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
    let TIME_DELAY: Int64 = 2
    let TIME_CALIBRATE: Int64 = 12
    let TIME_CHECK: Int64 = 13

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

        let timeCheck = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), TIME_CHECK * Int64(NSEC_PER_SEC))
        dispatch_after(timeCheck, dispatch_get_main_queue()) {
            self.finishGlassCalibration()
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
        tobiiGlass.checkCalibration(model.tobiiCurrentCalibration)
    }
    
    func finishGlassCalibration() {
        var message = "Calibration successful!"
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
}