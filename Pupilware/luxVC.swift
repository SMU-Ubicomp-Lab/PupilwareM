//
//  luxVC.swift
//  Pupilware
//
//  Created by Raymond Martin on 2/18/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

import Foundation
import UIKit

class luxVC: UIViewController{
    let model = DataModel.sharedInstance
    @IBOutlet weak var luxLabel: UILabel!
    @IBOutlet weak var proBar: UIProgressView!
    var timer = NSTimer()
    var delegate:sendBackDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.luxLabel.text = String(format: "%.2f", UIScreen.mainScreen().brightness)
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "updateLux", userInfo: nil, repeats: true)
    }
    
    func updateLux(){
        self.luxLabel.text = String(format: "%.2f", UIScreen.mainScreen().brightness)
        self.proBar.setProgress(Float(UIScreen.mainScreen().brightness), animated: true)
    }
    
    @IBAction func donePressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        timer.invalidate()
    }
}