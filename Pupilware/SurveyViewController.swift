//
//  SurveyViewController.swift
//  Pupilware
//
//  Created by Xinyi Ding on 9/8/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

import Foundation
import UIKit

class SurveyViewController: UIViewController {

    var quizId = 0
    let model = DataModel.sharedInstance
    
    @IBOutlet weak var slider1: StepSlider!
    
    @IBOutlet weak var slider2: StepSlider!
    
    @IBOutlet weak var slider3: StepSlider!
    
    @IBOutlet weak var slider4: StepSlider!
    
    
    @IBAction func finishSurvey(sender: UIButton) {
        saveData()
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
    
    func saveData() {
        let filePath = getDocumentsDirectory().stringByAppendingPathComponent(model.currentSubjectID + "_ACT_Surveys.csv")
        let stringSurvey = String(quizId) + "," +  String(slider1.value) + "," + String(slider2.value) + "," + String(slider3.value) + "," + String(slider4.value) + "\n"
        writeToCSV(filePath, row: stringSurvey)
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    func writeToCSV(fileName: String, row: String) {
        let data = row.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        
        if NSFileManager.defaultManager().fileExistsAtPath(fileName) {
            print("writing to " + fileName)
            if let fileHandle = NSFileHandle(forUpdatingAtPath: fileName) {
                fileHandle.seekToEndOfFile()
                fileHandle.writeData(data)
                fileHandle.closeFile()
            }
            else {
                print("Can't open fileHandle")
            }
        }
        else {
            NSFileManager.defaultManager().createFileAtPath(fileName, contents: nil, attributes: nil)
            print("File not exist")
            print("created" + fileName)
            if let fileHandle = NSFileHandle(forUpdatingAtPath: fileName) {
                fileHandle.seekToEndOfFile()
                fileHandle.writeData(data)
                fileHandle.closeFile()
            }
            else {
                print("Can't open fileHandle")
            }
        }
    }
}