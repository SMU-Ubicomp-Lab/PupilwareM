//
//  expModalVC.swift
//  Pupilware
//
//  Created by Raymond Martin on 1/29/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

import Foundation
import UIKit


class expModalVC: UIViewController, BridgeDelegate{
    let model = DataModel.sharedInstance
    @IBOutlet weak var topBar: UINavigationItem!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var indicator: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var completeButton: UIBarButtonItem!
    var delegate:sendBackDelegate?
    var testName:String = "Experiment N"
    var index:Int = 0
    var testStarted:Bool = false
    var testFinished = false
    var numberStoped = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.model.bridgeDelegate = self
        self.topBar.title = testName
        self.progressBar.setProgress(0, animated: true)
        self.completeButton.enabled = false
        
        testFinished = false
        numberStoped = false
        
    }
    
    //DELEGATE FUNCTIONS
    func trackingFaceDone(){
        
    }
    func startTrackingFace(){
        
    }
    func finishCalibration(){
    
        
    }
    
    func isTestingFinished() -> Bool {
        return testFinished;
    }
    
    func isNumberStarted() -> Bool{
        return testStarted;
    }
    
    func isNumberStoped() -> Bool{
        return numberStoped;
    }
    
    func faceInView(){
        if self.testStarted{return}
        
        if (self.progressBar.progress >= 1){
            self.loadingView.hidden = true
            self.startDigitSpanTest()
            self.testStarted = true
            return
        }
        
        self.indicator.text = "Keep Face In View"
        self.indicator.textColor = UIColor.greenColor().colorWithAlphaComponent(0.5)
        self.progressBar.setProgress(self.progressBar.progress + 0.005, animated: true)
    }
    
    func faceNotInView(){
        self.indicator.text = "Face Not In View"
        self.indicator.textColor = UIColor.redColor().colorWithAlphaComponent(0.5)
        self.progressBar.setProgress(0, animated: true)
    }
    
    
    func startDigitSpanTest()
    {
        var numbers:[Int] = (model.currentTest?.getDigits())!
        UIView.animateWithDuration(0.5, delay: 1.0, options: UIViewAnimationOptions.CurveEaseOut, animations:
            {
                self.mainLabel!.alpha = 0.0
            },
            completion:
            {(finished: Bool) -> Void in
                self.mainLabel!.text = String(numbers[self.index])
                // Fade in
                UIView.animateWithDuration(0.25, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations:
                    {
                        self.mainLabel!.alpha = 1.0
                    },
                    completion:
                    {(finished: Bool) -> Void in
                        self.index += 1
                        if self.index < numbers.count{
                            
                            // There is numbers left, start face in that number again.
                            self.startDigitSpanTest()
                            
                        }else if (self.index == numbers.count){
                            
                            // If there is no number left, as the participant to repeat
                            self.numberStoped = true;
                            self.mainLabel!.text = "repeat back"
                            self.mainLabel.font = self.mainLabel.font.fontWithSize(25)
                
                            UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations:
                            {
                                    self.mainLabel!.alpha = 1.0
                            },
                            completion:{(finished: Bool) -> Void in
                                NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(expModalVC.testCompleted), userInfo: nil, repeats: false)
                            })
                        }
                })
        })
    }
    
    func testCompleted(){
        self.completeButton.enabled = true
        
    }
    
    @IBAction func completePressed(sender: AnyObject) {
        testFinished = true;
        if testFinished {
            self.dismissViewControllerAnimated(true, completion: nil)
            delegate?.digitSpanTestComplete()
        }
        
    }
    
    override func viewDidDisappear(animated: Bool) {
    }
    
}