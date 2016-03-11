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
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var completeButton: UIBarButtonItem!
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
        timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "updateFaceView", userInfo: nil, repeats: true)
        self.progressBar.setProgress(0, animated: true)
        self.completeButton.enabled = false
    }
    
    @IBAction func tapDone(sender: AnyObject) {
        delegate?.digitSpanTestComplete(lum, digits: digits, iter: iter)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func updateFaceView(){
        if (self.progressBar.progress >= 1){
            self.loadingView.hidden = true
            self.startDigitSpanTest()
            timer?.invalidate()
            return
        }
        
        print(self.model.faceInView)
        
        if(self.model.faceInView){
            self.indicator.text = "Keep Face In View"
            self.indicator.textColor = UIColor.greenColor().colorWithAlphaComponent(0.5)
            self.progressBar.setProgress(self.progressBar.progress + 0.1, animated: true)
        }else{
            self.indicator.text = "Face Not In View"
            self.indicator.textColor = UIColor.redColor().colorWithAlphaComponent(0.5)
            self.progressBar.setProgress(0, animated: true)
        }
    }
    
    func startDigitSpanTest()
    {
        var numbers:[Int] = model.digitsForTest(digits, iter: iter)
        UIView.animateWithDuration(1.0, delay: 1.0, options: UIViewAnimationOptions.CurveEaseOut, animations:
            {
                self.mainLabel!.alpha = 0.0
            },
            completion:
            {(finished: Bool) -> Void in
                self.mainLabel!.text = String(numbers[self.index])
                // Fade in
                UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations:
                    {
                        self.mainLabel!.alpha = 1.0
                    },
                    completion:
                    {(finished: Bool) -> Void in
                        self.index++
                        if self.index < numbers.count{
                            self.startDigitSpanTest()
                        }else if (self.index == numbers.count){
                            self.mainLabel!.text = "repeat back"
                            self.mainLabel.font = self.mainLabel.font.fontWithSize(25)
                            UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations:
                            {
                                    self.mainLabel!.alpha = 1.0
                            },
                            completion:{(finished: Bool) -> Void in
                                NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "testCompleted", userInfo: nil, repeats: false)
                            })
                        }
                })
        })
    }
    
    func testCompleted(){
        self.completeButton.enabled = true
    }
    
    @IBAction func completePressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        delegate?.digitSpanTestComplete((model.currentTest?.lux)!, digits: (model.currentTest?.digits)!, iter: (model.currentTest?.iter)!)
    }
    
    override func viewDidDisappear(animated: Bool) {
        timer?.invalidate()
    }
    
}