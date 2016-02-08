//
//  expModalVC.swift
//  Pupilware
//
//  Created by Raymond Martin on 1/29/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

import Foundation
import UIKit

class expModalVC: UIViewController{
    let model = DataModel.sharedInstance
    @IBOutlet weak var topBar: UINavigationItem!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var indicator: UILabel!
    var delegate:sendBackDelegate?
    var testName:String = "Experiment N"
    var digits:Int = 5
    var lum:Int = 1
    var iter:Int = 1
    var index:Int = 0
    var timer:NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.topBar.title = testName
        self.startDigitSpanFade()
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "updateFaceView", userInfo: nil, repeats: true)
    }
    
    @IBAction func tapDone(sender: AnyObject) {
        //delegate?.digitSpanTestComplete(lum, digits: digits, iter: iter)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func updateFaceView(){
        if(self.model.faceInView){
            self.indicator.textColor = UIColor.greenColor().colorWithAlphaComponent(0.5)
        }else{
            self.indicator.textColor = UIColor.redColor().colorWithAlphaComponent(0.5)
        }
    }
    
    func startDigitSpanFade()
    {
        var hello:[Int] = model.digitsForTest(digits, iter: iter)
        UIView.animateWithDuration(1.0, delay: 1.0, options: UIViewAnimationOptions.CurveEaseOut, animations:
            {
                self.mainLabel!.alpha = 0.0
            },
            completion:
            {(finished: Bool) -> Void in
                self.mainLabel!.text = String(hello[self.index])
                // Fade in
                UIView.animateWithDuration(1.0, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations:
                    {
                        self.mainLabel!.alpha = 1.0
                    },
                    completion:
                    {(finished: Bool) -> Void in
                        self.index++
                        if self.index < hello.count{
                            self.startDigitSpanFade()
                        }else{
                            //FINISH AND DISMISS VIEW
                        }
                })
        })
    }
    
    override func viewDidDisappear(animated: Bool) {
        timer = NSTimer()
    }
    
}