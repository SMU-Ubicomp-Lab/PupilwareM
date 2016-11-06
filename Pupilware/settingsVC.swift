//
//  settingsVC.swift
//  Pupilware
//
//  Created by Raymond Martin on 3/11/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//


import Foundation
import UIKit

class settingsVC: UIViewController{
    var delegate:sendBackDelegate?
    let model = DataModel.sharedInstance
    @IBOutlet weak var dist: UITextField!
    @IBOutlet weak var movAvg: UITextField!
    @IBOutlet weak var medianBlur: UITextField!
    @IBOutlet weak var baseStart: UITextField!
    @IBOutlet weak var baseEnd: UITextField!
    @IBOutlet weak var thresh: UITextField!
    @IBOutlet weak var markCost: UITextField!
    @IBOutlet weak var baseline: UITextField!
    @IBOutlet weak var cogHigh: UITextField!
    
    @IBOutlet weak var sysStatus: UILabel!
    @IBOutlet weak var battery: UILabel!    
    @IBOutlet weak var storage: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dist.keyboardType = .NumberPad
        movAvg.keyboardType = .NumberPad
        medianBlur.keyboardType = .NumberPad
        baseStart.keyboardType = .NumberPad
        baseEnd.keyboardType = .NumberPad
        thresh.keyboardType = .NumberPad
        markCost.keyboardType = .NumberPad
        baseline.keyboardType = .NumberPad
        cogHigh.keyboardType = .NumberPad
        
        dist.text = String(model.settings.dist)
        movAvg.text = String(model.settings.movAvg)
        medianBlur.text = String(model.settings.medBlur)
        baseStart.text = String(model.settings.baseStart)
        baseEnd.text = String(model.settings.baseEnd)
        thresh.text = String(model.settings.thresh)
        markCost.text = String(model.settings.markCost)
        baseline.text = String(model.settings.baseline)
        cogHigh.text = String(model.settings.cogHigh)
        
        //Tobii Glass
        sysStatus.text = model.systemStatus
        battery.text = model.batteryLevel
        storage.text = model.storageLevel
    }
    
    @IBAction func donePressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
        model.settings.dist     = Int(dist.text!)!
        model.settings.movAvg   = Int(movAvg.text!)!
        model.settings.medBlur  = Int(medianBlur.text!)!
        model.settings.baseStart = Int(baseStart.text!)!
        model.settings.baseEnd  = Int(baseEnd.text!)!
        model.settings.thresh   = Int(thresh.text!)!
        model.settings.markCost = Int(markCost.text!)!
        model.settings.baseline = Int(baseline.text!)!
        model.settings.cogHigh  = Int(cogHigh.text!)!
        
        
        dist.text = String(model.settings.dist)
        movAvg.text = String(model.settings.movAvg)
        medianBlur.text = String(model.settings.medBlur)
        baseStart.text = String(model.settings.baseStart)
        baseEnd.text = String(model.settings.baseEnd)
        thresh.text = String(model.settings.thresh)
        markCost.text = String(model.settings.markCost)
        baseline.text = String(model.settings.baseline)
        cogHigh.text = String(model.settings.cogHigh)
    }
    
}

