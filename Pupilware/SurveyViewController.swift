//
//  SurveyViewController.swift
//  Pupilware
//
//  Created by Xinyi Ding on 9/8/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

import Foundation
import UIKit

class SurveyViewController: UIViewController {

    var quizNo = 0
    
    
    @IBOutlet weak var slider1: StepSlider!
    
    @IBOutlet weak var slider2: StepSlider!
    
    
    @IBOutlet weak var slider3: StepSlider!
    
    
    @IBOutlet weak var slider4: StepSlider!
    
    
    @IBAction func finishSurvey(sender: UIButton) {
        print(self.quizNo)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    override func viewDidLoad() {
         super.viewDidLoad()
        
        self.slider1.customTrack = true
        self.slider1.minValue = 0
        self.slider1.maxValue = 5
        self.slider1.steps = 6
        self.slider1.value = 0
        
        self.slider2.customTrack = true
        self.slider2.minValue = 0
        self.slider2.maxValue = 5
        self.slider2.steps = 6
        self.slider2.value = 0
        
        self.slider3.customTrack = true
        self.slider3.minValue = 0
        self.slider3.maxValue = 5
        self.slider3.steps = 6
        self.slider3.value = 0
        
        self.slider4.customTrack = true
        self.slider4.minValue = 0
        self.slider4.maxValue = 5
        self.slider4.steps = 6
        self.slider4.value = 0
    }
}