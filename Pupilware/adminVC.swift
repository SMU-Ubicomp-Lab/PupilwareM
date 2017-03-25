//
//  adminVC.swift
//  Pupilware
//
//  Created by Raymond Martin on 2/18/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//


import Foundation
import UIKit

class adminVC: UIViewController{
    var delegate:sendBackDelegate?
    let model = DataModel.sharedInstance
    let tobiiGlass = TobiiGlass.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func clearProgressButton(sender: AnyObject) {
        self.warningAlert("CLEAR ALL PROGRESS", handle: self.clearProgress)
    }
    
    @IBAction func clearUsersButton(sender: AnyObject) {
        self.warningAlert("CLEAR ALL USERS", handle: self.clearUsers)
    }
    
    @IBAction func clearDataButton(sender: AnyObject) {
        self.warningAlert("CLEAR ALL DATA", handle: self.clearData)
    }
    
    func warningAlert(title:String, handle:()->()){
        let alert = UIAlertController(title: title, message: "are you sure you want to do this?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "YES", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) in
            handle()
        }));
        alert.addAction(UIAlertAction(title: "NO", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func clearProgress(){
        print("handled")
        
    }
    
    func clearUsers(){
        
    }
    
    func clearData(){
        
    }
    
    @IBAction func donePressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    

    @IBAction func newProject(sender: UIButton) {
        let alertController = UIAlertController(title: "Enter Project ID", message: "", preferredStyle: .Alert)
        let loginAction = UIAlertAction(title: "Done", style: .Default) { (_) in
            let textBox = alertController.textFields![0] as UITextField
            var name = ""
            if textBox.text != nil{
                name = textBox.text!
            }
            self.model.currentProject = name
            self.tobiiGlass.createProject()
        }
        loginAction.enabled = false
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Project ID"
            
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                loginAction.enabled = textField.text != ""
            }
        }
        
        alertController.addAction(loginAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true){ (_) in}
    }
}
