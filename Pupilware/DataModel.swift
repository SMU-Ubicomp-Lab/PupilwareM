//
//  DataModel.swift
//  Pupilware
//
//  Created by Raymond Martin on 1/27/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

import Foundation

@objc class DataModel: NSObject, NSCoding{
    static let sharedInstance = DataModel()
    var currentSubjectID:String = ""
    var allSubjectIDs:[String] = []
    var faceInView:Bool = false
    var currentTest:DigitTest?
    var digitIteration = 0
    var calibrationNum = 1
    var settings = (dist:60, movAvg:11, medBlur:11, baseStart:20, baseEnd:40, thresh:15, markCost:1, baseline: 0, cogHigh:0)
    var lumMode = true
    var digitTestLumProgress = [
        1: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        2: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        3: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        4: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        5: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
    ] as [Int:[Int:[Bool]]]
    
    var digitTestAngleProgress = [
        1: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        2: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        3: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        4: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        5: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        ] as [Int:[Int:[Bool]]]
    
    override init(){
        super.init()
        self.fetchSubjectIDs()
    }
    
    func fetchSubjectIDs(){
        if let data = NSUserDefaults.standardUserDefaults().objectForKey("allSubjectIDs") as? NSData {
            self.allSubjectIDs = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [String]
        }
    }
    
    func archiveSubjectIDs(){
        let data = NSKeyedArchiver.archivedDataWithRootObject(allSubjectIDs)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: "allSubjectIDs")
    }
    
    func getRighEyeName()->NSString{
        return self.currentTest!.labels.rightEye
    }
    
    func getLeftEyeName()->NSString{
        return self.currentTest!.labels.leftEye
    }
    
    func getCSVFileName()->NSString{
        return self.currentTest!.labels.csvFile
    }
    
    func calParamFileName()->NSString{
        return self.currentTest!.labels.calFile
    }
    
    func saveNewCalibrationFiles(){
        calibrationNum++
    }
    
    func getCalibrationRightEye()->NSString{
        return String(calibrationNum) + "_calibration_right_eye";
    }
    
    func getCalibrationLeftEye()->NSString{
        return String(calibrationNum) + "_calibration_left_eye";
    }
    
    required init(coder decoder: NSCoder) {
        self.calibrationNum = decoder.decodeIntegerForKey("caliNum")
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeInt(Int32(self.calibrationNum), forKey: "caliNum")
    }
    
    func resetProgress(){
        digitTestLumProgress = [
            0: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            1: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            2: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            3: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            4: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            ] as [Int:[Int:[Bool]]]
        
        digitTestAngleProgress = [
            0: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            1: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            2: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            3: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            4: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            ] as [Int:[Int:[Bool]]]
    }
    
    
    func completeTest(lum:Int, digit:Int, iter:Int){
        if self.lumMode{
            self.digitTestLumProgress[lum]![digit]![iter-1] = true
        }else{
            self.digitTestAngleProgress[lum]![digit]![iter-1] = true
        }
    }
    
    func isTestComplete(lum:Int, digit:Int, iter:Int)->Bool{
        if self.lumMode{
            return self.digitTestLumProgress[lum+1]![digit]![iter-1]
        }else{
            return self.digitTestAngleProgress[lum+1]![digit]![iter-1]
        }
    }
}


@objc class DigitTest: NSObject{
    let model = DataModel.sharedInstance
    var digits:Int, iter:Int, lux:Int, exact_lux:Double, subjectID:String, angle:Int
    var labels = (rightEye:"", leftEye:"", csvFile:"", calFile:"", rightEyeBase:"", leftEyeBase:"", csvFileBase:"", calFileBase:"")
    
    
    init(subjectID:String, digits:Int, iter:Int, lux:Int, exact_lux:Double){
        self.digits = digits
        self.iter = iter
        self.lux = lux
        self.exact_lux = exact_lux
        self.subjectID = subjectID
        self.angle = -1
        self.labels.rightEyeBase = "\(subjectID)_lux\(lux)_\(digits)digits_iter\(iter)_righteye"
        self.labels.leftEyeBase = "\(subjectID)_lux\(lux)_\(digits)digits_iter\(iter)_lefteye"
        self.labels.csvFileBase = "\(subjectID)_lux\(lux)_\(digits)digits_iter\(iter)_data"
        self.labels.calFileBase = "\(subjectID)_lux\(lux)_\(digits)digits_iter\(iter)_calibration"
    }
    
    init(subjectID:String, digits:Int, iter:Int, angle:Int, exact_lux:Double){
        self.digits = digits
        self.iter = iter
        self.lux = -1
        self.exact_lux = exact_lux
        self.subjectID = subjectID
        self.angle = angle
        self.labels.rightEyeBase = "\(subjectID)_lux\(lux)_\(digits)digits_iter\(iter)_righteye"
        self.labels.leftEyeBase = "\(subjectID)_lux\(lux)_\(digits)digits_iter\(iter)_lefteye"
        self.labels.csvFileBase = "\(subjectID)_lux\(lux)_\(digits)digits_iter\(iter)_data"
        self.labels.calFileBase = "\(subjectID)_lux\(lux)_\(digits)digits_iter\(iter)_calibration"
    }
    
    func completeTest(){
        if lux == -1{
             model.completeTest(angle, digit: digits, iter: iter)
        }else{
            model.completeTest(lux, digit: digits, iter: iter)
        }
    }
    
    func getDigits()->[Int]{
        switch digits{
            case 5:
                switch iter{
                case 1:return [1, 2, 3, 4, 5]
                case 2:return [1, 2, 3, 4, 5]
                case 3:return [1, 2, 3, 4, 5]
                case 4:return [1, 2, 3, 4, 5]
                default:print("DIGIT TEST NOT FOUND")
                }
            case 6:
                switch iter{
                case 1:return [1, 2, 3, 4, 5, 6]
                case 2:return [1, 2, 3, 4, 5, 6]
                case 3:return [1, 2, 3, 4, 5, 6]
                case 4:return [1, 2, 3, 4, 5, 6]
                default:print("DIGIT TEST NOT FOUND")
                }
            case 7:
                switch iter{
                case 1:return [1, 2, 3, 4, 5, 6, 7]
                case 2:return [1, 2, 3, 4, 5, 6, 7]
                case 3:return [1, 2, 3, 4, 5, 6, 7]
                case 4:return [1, 2, 3, 4, 5, 6, 7]
                default:print("DIGIT TEST NOT FOUND")
                }
            case 8:
                switch iter{
                case 1:return [1, 2, 3, 4, 5, 6, 7, 8]
                case 2:return [1, 2, 3, 4, 5, 6, 7, 8]
                case 3:return [1, 2, 3, 4, 5, 6, 7, 8]
                case 4:return [1, 2, 3, 4, 5, 6, 7, 8]
                default:print("DIGIT TEST NOT FOUND")
                }
            default:
                print("DIGIT TEST NOT FOUND")
            }
        return []
    }
    
    func getTimeStamp()->String{
        let currentDateTime = NSDate()
        let formatter = NSDateFormatter()
        formatter.timeStyle = NSDateFormatterStyle.MediumStyle
        formatter.dateStyle = NSDateFormatterStyle.ShortStyle
        return formatter.stringFromDate(currentDateTime)
    }
    
    func writeData(){
        var attempt = 1
        while (attempt <= 999){
            let fileName = "\(subjectID)_lux\(lux)_\(digits)digits_iter\(iter)_\(String(format: "%03d", attempt)).json"
            self.labels.rightEye = "\(self.labels.rightEyeBase)_\(String(format: "%03d", attempt))"
            self.labels.leftEye = "\(self.labels.leftEyeBase)_\(String(format: "%03d", attempt))"
            self.labels.csvFile = "\(self.labels.csvFileBase)_\(String(format: "%03d", attempt))"
            self.labels.calFile = "\(self.labels.calFileBase)_\(String(format: "%03d", attempt))"
            if(self.writeJSONFile(fileName)){
                break
            }
            attempt += 1
            print("WRITE FAILED CRITICAL ERROR ATTEMPT: \(attempt)")
        }
    }
    
    func writeJSONFile(fileName:String)->Bool{
        let data: [String: AnyObject] = [
            "user_id": self.subjectID,
            "type" : "digit span",
            "digits" : self.digits,
            "iteration": self.iter,
            "lux_level" : self.lux,
            "exact_lux_level" : self.exact_lux,
            "angle" : self.angle,
            "right_eye_file_name" : self.labels.rightEye,
            "left_eye_file_name" : self.labels.leftEye,
            "csv_data_file_name" : self.labels.csvFile,
            "calibration_right_eye" : model.getCalibrationRightEye(),
            "calibration_left_eye" : model.getCalibrationLeftEye(),
            "parameter_file" : self.labels.calFile,
            "write_time" : self.getTimeStamp()
        ]
        
        var jsonData: NSData!
        do {
            jsonData = try NSJSONSerialization.dataWithJSONObject(data, options: NSJSONWritingOptions())
            let jsonString = String(data: jsonData, encoding: NSUTF8StringEncoding)
            print(jsonString!)
        } catch let error as NSError {
            print("Array to JSON conversion failed: \(error.localizedDescription)")
        }
        
        let documentsDirectoryPathString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        let documentsDirectoryPath = NSURL(string: documentsDirectoryPathString)!
        
        let jsonFilePath = documentsDirectoryPath.URLByAppendingPathComponent(fileName)
        let fileManager = NSFileManager.defaultManager()
        var isDirectory: ObjCBool = false
        
        // creating a .json file in the Documents folder
        if !fileManager.fileExistsAtPath(jsonFilePath.absoluteString, isDirectory: &isDirectory) {
            let created = fileManager.createFileAtPath(jsonFilePath.absoluteString, contents: nil, attributes: nil)
            if created {
                print("File created")
                do {
                    let file = try NSFileHandle(forWritingToURL: jsonFilePath)
                    file.writeData(jsonData)
                    print("JSON data was written to the file successfully!")
                } catch let error as NSError {
                    print("Couldn't write to file: \(error.localizedDescription)")
                }
            } else {
                print("Couldn't create file for some reason")
            }
        } else {
            print("File already exists")
            return false
        }
        return true
    }
}
