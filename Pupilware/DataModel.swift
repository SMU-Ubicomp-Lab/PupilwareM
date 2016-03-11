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
    var digitTestProgress = [
        0: [5:[false, false, false, true],6:[false, false, false, false],7:[false, false, false, false],8:[false, false, false, false]],
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
    
    
    func completeTest(lum:Int, digit:Int, iter:Int){
        //
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
            case 1:return [1, 2, 3, 4, 5]
            case 2:return [1, 2, 3, 4, 5]
            case 3:return [1, 2, 3, 4, 5]
            case 4:return [1, 2, 3, 4, 5]
            default:print("DIGIT TEST NOT FOUND")
            }
        case 7:
            switch iter{
            case 1:return [1, 2, 3, 4, 5]
            case 2:return [1, 2, 3, 4, 5]
            case 3:return [1, 2, 3, 4, 5]
            case 4:return [1, 2, 3, 4, 5]
            default:print("DIGIT TEST NOT FOUND")
            }
        case 8:
            switch iter{
            case 1:return [1, 2, 3, 4, 5]
            case 2:return [1, 2, 3, 4, 5]
            case 3:return [1, 2, 3, 4, 5]
            case 4:return [1, 2, 3, 4, 5]
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
    
    init(subjectID:String, digits:Int, iter:Int, lux:Int, exact_lux:Double){
        self.digits = digits
        self.iter = iter
        self.lux = lux
        self.exact_lux = exact_lux
        self.subjectID = subjectID
    }
    
   /* func writeJSON(){
        let jsonObject: [String: AnyObject] = [
            "userid": self.subjectID,
            "type" : "target",
            "digits" : self.digits,
            "iteration": self.iter,
            "lux level" : self.lux,
            "exact lux" : self.exact_lux
        ]
        
        //let valid = NSJSONSerialization.isValidJSONObject(jsonObject)
        
    }*/
    
}
