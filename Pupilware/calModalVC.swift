//
//  calModalVC.swift
//  Pupilware
//
//  Created by Raymond Martin on 2/7/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

import Foundation
import UIKit

class calModalVC: UIViewController{
    let model = DataModel.sharedInstance
    var testName:String = "Calibration"
    @IBOutlet weak var topBar: UINavigationItem!
    var delegate:sendBackDelegate?
    var lum:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.topBar.title = testName
    }
    
    @IBAction func tapDone(sender: AnyObject) {
        delegate?.calibrationComplete(lum)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}