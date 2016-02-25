//
//  adminVC.swift
//  Pupilware
//
//  Created by Raymond Martin on 2/18/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//


import Foundation
import UIKit

class adminVC: UIViewController{
    var delegate:sendBackDelegate?

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
    
}
