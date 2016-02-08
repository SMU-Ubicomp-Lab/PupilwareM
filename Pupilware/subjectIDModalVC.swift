//
//  subjectIDModalVC.swift
//  Pupilware
//
//  Created by Raymond Martin on 1/27/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

import Foundation
import UIKit

class subjectIDModalVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let model = DataModel.sharedInstance
    @IBOutlet weak var subjectTable: UITableView!
    var delegate:sendBackDelegate?
    
    
    @IBAction func newSubjectPressed(sender: AnyObject) {
        self.presentNewUserPrompt()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int)->Int {
        return self.model.allSubjectIDs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell")
        cell!.textLabel!.text = self.model.allSubjectIDs[self.model.allSubjectIDs.count - indexPath.row - 1]
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        self.model.currentSubjectID = self.model.allSubjectIDs[self.model.allSubjectIDs.count - indexPath.row - 1]
        delegate?.subjectIDChosen()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func presentNewUserPrompt(){
        let alertController = UIAlertController(title: "Enter Subject ID", message: "", preferredStyle: .Alert)
        let loginAction = UIAlertAction(title: "Done", style: .Default) { (_) in
            let textBox = alertController.textFields![0] as UITextField
            var name = ""
            if textBox.text != nil{
                name = textBox.text!
            }
            
            //if (name.characters.count > 0 && !self.model.allSubjectIDs.contains(name)){
                self.model.allSubjectIDs.append(name)
                self.model.currentSubjectID = name
            //}
            
            self.model.archiveSubjectIDs()
            self.subjectTable.reloadData()
        }
        loginAction.enabled = false
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Subject ID"
            
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                loginAction.enabled = textField.text != ""
            }
        }
        
        alertController.addAction(loginAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true){ (_) in}
    }
}
