//
//  DataModel.swift
//  Pupilware
//
//  Created by Raymond Martin on 1/27/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

import Foundation

@objc class DataModel:NSObject{
    static let sharedInstance = DataModel()
    var currentSubjectID:String = ""
    var allSubjectIDs:[String] = []
    var faceInView:Bool = false
    var currentTest:DigitTest?
    var digitIteration = 0
    var settings = (dist:60, movAvg:11, medBlur:11, baseStart:20, baseEnd:40, thresh:15, markCost:1, baseline: 0, cogHigh:0)
    var digitTestProgress = [
        0: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        1: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        2: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        3: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
        4: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
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
    
    func resetProgress(){
        digitTestProgress = [
            0: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            1: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            2: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            3: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            4: [5:[false, false, false, false],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
            ] as [Int:[Int:[Bool]]]
    }
    
    
    func completeTest(lum:Int, digit:Int, iter:Int){
        self.digitTestProgress[lum]![digit]![iter-1] = true
    }
    
    func isTestComplete(lum:Int, digit:Int, iter:Int)->Bool{
        return self.digitTestProgress[lum]![digit]![iter-1]
    }
    
    func digitsForTest(digits: Int, iter: Int)->[Int]{
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
}


class DigitTest{
    var digits:Int, iter:Int, lux:Int, exact_lux:Double, subjectID:String
    var labels = (rightEye:"", leftEye:"", csvFile:"", rightEyeBase:"", leftEyeBase:"", csvFileBase:"")
    
    init(subjectID:String, digits:Int, iter:Int, lux:Int, exact_lux:Double){
        self.digits = digits
        self.iter = iter
        self.lux = lux
        self.exact_lux = exact_lux
        self.subjectID = subjectID
        self.labels.rightEyeBase = "\(subjectID)_lux\(lux)_\(digits)digits_iter\(iter)_righteye"
        self.labels.leftEyeBase = "\(subjectID)_lux\(lux)_\(digits)digits_iter\(iter)_lefteye"
        self.labels.csvFileBase = "\(subjectID)_lux\(lux)_\(digits)digits_iter\(iter)_data"
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
            let fileName = "\(subjectID)_lux\(lux)_\(digits)digits_iter\(iter)_\(String(format: "%03d", attempt)).json)"
            self.labels.rightEye = "\(self.labels.rightEyeBase)_\(String(format: "%03d", attempt))"
            self.labels.leftEye = "\(self.labels.leftEyeBase)_\(String(format: "%03d", attempt))"
            self.labels.csvFile = "\(self.labels.csvFileBase)_\(String(format: "%03d", attempt))"
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
            "type" : "target",
            "digits" : self.digits,
            "iteration": self.iter,
            "lux_level" : self.lux,
            "exact_lux_level" : self.exact_lux,
            "right_eye_file_name" : self.labels.rightEye,
            "left_eye_file_name" : self.labels.leftEye,
            "csv_data_file_name" : self.labels.csvFile,
            "write_time" : self.getTimeStamp()
        ]
        
        var jsonData: NSData!
        do {
            jsonData = try NSJSONSerialization.dataWithJSONObject(data, options: NSJSONWritingOptions())
            let jsonString = String(data: jsonData, encoding: NSUTF8StringEncoding)
            print(jsonString)
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
