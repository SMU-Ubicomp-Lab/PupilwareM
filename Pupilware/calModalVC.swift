//
//  calModalVC.swift
//  Pupilware
//
//  Created by Raymond Martin on 2/7/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

import Foundation
import UIKit

class calModalVC: UIViewController, BridgeDelegate{
    let model = DataModel.sharedInstance
    var testName:String = "Calibration"
    @IBOutlet weak var topBar: UINavigationItem!
    var delegate:sendBackDelegate?
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var loadingIcon: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        print("In calModalVC.swift")
        super.viewDidLoad()
        self.model.bridgeDelegate = self
        self.topBar.title = testName
    }
    
    @IBAction func tapDone(sender: AnyObject) {
        delegate?.calibrationComplete()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func trackingFaceDone(){
        self.mainLabel.text = "Optimizing Parameters"
    }
    
    func finishCalibration(){
        print("calibration finished")
        delegate?.calibrationComplete()
        self.dismissViewControllerAnimated(true, completion: nil)
        if (self.model.tobiiCurrentCalibrationState == "calibrated") {
            print("Tobii calibration success")
        } else {
            print("Tobii calibration failed")
        }
    }
    
    func startTrackingFace(){
        
    }
    func faceInView(){
        
    }
    func faceNotInView(){
        
    }
    
}