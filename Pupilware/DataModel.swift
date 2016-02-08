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
    var digitIteration = 0
    var targetIteration = 0
    var faceInView:Bool = false
    
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
