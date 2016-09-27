//
//  settingsPopVC
//  Pupilware
//
//  Created by Raymond Martin on 1/27/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

import Foundation
import UIKit

class popOverController: UITableViewController{
    let model = DataModel.sharedInstance
    @IBOutlet var settingTable: UITableView!
    @IBOutlet var iterTable: UITableView!
    var delegate:sendBackDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        if iterTable != nil{
            delegate?.iterChosen(indexPath.row + 1)
        }else if settingTable != nil{
            switch indexPath.row{
            case 0:
                delegate?.presentIDPicker()
            case 1:
                delegate?.presentLuxMeter()
            case 2:
                delegate?.presentAdminPage()
            case 3:
                delegate?.presentSettingsPage()
            case 4:
                delegate?.switchModes()
            default:break
            }
        }
        
    }
}


protocol sendBackDelegate{
    func iterChosen(iter:Int)
    func presentIDPicker()
    func subjectIDChosen()
    func calibrationComplete()
    func digitSpanTestComplete()
    func presentLuxMeter()
    func switchModes()
    func presentAdminPage()
    func presentSettingsPage()
}