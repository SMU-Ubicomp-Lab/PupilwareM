//
//  targetSettupVC.swift
//  Pupilware
//
//  Created by Raymond Martin on 3/21/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//
//
//  tabViewController.swift
//  Pupilware
//
//  Created by Raymond Martin on 1/29/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

import Foundation
import UIKit

class targetSetupVC: UIViewController, UIPopoverPresentationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, sendBackDelegate{
    let model = DataModel.sharedInstance
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var targetCollection: UICollectionView!
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var contTitle: UILabel!
    @IBOutlet weak var expBlock: UIView!
    var targetNum = 1
    var iter = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (self.model.currentSubjectID == ""){
            self.presentSubjectID()
        }
        
        self.targetCollection.allowsMultipleSelection = true
        self.containerView.layer.cornerRadius = 5
        self.expBlock.layer.cornerRadius = 5
        self.contTitle.text = "Welcome " + model.currentSubjectID
    }
    
    @IBAction func tapSettings(sender: AnyObject) {
        self.presentSettingsPopover(sender)
    }
    
    @IBAction func startTargetTest(sender: AnyObject) {
        model.currentTest = TargetTest(subjectID: model.currentSubjectID, missing_digits: self.targetNum, iter: self.iter, exact_lux: Double(UIScreen.mainScreen().brightness))
        self.presentTargetTestModal()
    }
    
    @IBAction func shortPressCalibrate(sender: AnyObject) {
        self.presentCalibrationModal()
    }
    
    func checkStartButton(){
        if self.model.digitIteration > 0{
            self.startButton.enabled = true
        }
    }
    
    func switchModes(){
        self.dismissViewControllerAnimated(true, completion:nil)
    }
    
    //Custom Delgate functions___________________________________________
    func iterChosen(iter:Int){
        //self.iterLabel.setTitle(String(iter), forState: .Normal)
        self.model.digitIteration = iter
        self.dismissViewControllerAnimated(true, completion:nil)
        self.checkStartButton()
    }
    
    func presentIDPicker() {
        self.dismissViewControllerAnimated(true, completion:nil)
        self.presentSubjectID()
    }
    
    func subjectIDChosen() {
        contTitle.text = "Welcome " + model.currentSubjectID
    }
    
    func calibrationComplete(){
        expBlock.hidden = true
    }
    
    func digitSpanTestComplete(){
        print(model.digitTestLumProgress)
        model.currentTest?.completeTest()
        model.currentTest = nil
        print(model.digitTestLumProgress)
        self.targetCollection.reloadData()
    }
    
    func presentLuxMeter(){
        self.dismissViewControllerAnimated(true, completion:nil)
        self.presentModalView("lux")
    }
    
    
    func presentAdminPage(){
        self.dismissViewControllerAnimated(true, completion:nil)
        self.presentModalView("admin")
    }
    
    func presentSettingsPage() {
        self.dismissViewControllerAnimated(true, completion:nil)
        self.presentModalView("setters")
    }
    
    //Collection View Delegate Functions________________________________
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell:iterCell = collectionView.dequeueReusableCellWithReuseIdentifier("header", forIndexPath: indexPath) as! iterCell
        cell.frame.size.width = self.targetCollection.frame.width - 10
        cell.frame.size.height = self.targetCollection.frame.height/5 - 10
        cell.digit = (indexPath.row%4) + 5
        cell.iter = indexPath.row
        
        if (cell.iter == 0){
            cell.header = true
            cell.label.text = "Target Iterations"
        }else{
            cell.header = false
            cell.label.text = String(cell.iter)
        }
        
        cell.resetCell()
        
        if (!cell.header && model.isTargetTestComplete(cell.iter)){
            cell.setDone()
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: self.targetCollection.frame.width - 10,height: self.targetCollection.frame.height/5 - 10);
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 10, 0, 10);
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10;
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        for cell in collectionView.visibleCells() as! [iterCell] {
            cell.resetCell()
            if (!cell.header && model.isTargetTestComplete(cell.iter)){
                cell.setDone()
            }
        }
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! iterCell
        if (cell.header){
            return
        }else{
            cell.setSelected()
            self.iter = cell.iter
            self.targetNum = cell.digit
            self.startButton.enabled = true
        }
    }
    
    //Helper functions___________________________________________________
    //(most of this is presentation boiler plate code)
    func presentTargetTestModal(){
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("digitTest") as! expModalVC;
        vc.testName = String(self.targetNum) + "Target : Iter " + String(self.iter) + " Test"
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        self.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        self.modalPresentationStyle = .CurrentContext
        self.presentViewController(nav, animated: true, completion: nil)
    }
    
    func presentCalibrationModal(){
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("calibrate") as! calModalVC;
        vc.testName = "Target Test Calibration"
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        self.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        self.modalPresentationStyle = .CurrentContext
        self.presentViewController(nav, animated: true, completion: nil)
    }
    
    func presentSettingsPopover(sender: AnyObject){
        let vc = storyboard!.instantiateViewControllerWithIdentifier("settings") as! popOverController
        vc.delegate = self
        vc.modalPresentationStyle = .Popover
        let pres = vc.popoverPresentationController
        pres?.permittedArrowDirections = .Any
        pres?.delegate = self
        pres?.barButtonItem = sender as? UIBarButtonItem
        presentViewController(vc, animated: true, completion: nil)
    }
    
    func presentIterationPopover(sender: AnyObject){
        let vc = storyboard!.instantiateViewControllerWithIdentifier("iteration") as! popOverController
        vc.delegate = self
        vc.modalPresentationStyle = .Popover
        let pres = vc.popoverPresentationController
        pres?.permittedArrowDirections = .Up
        pres?.delegate = self
        pres?.sourceView = sender as? UIView
        pres?.sourceRect = CGRect(
            x: sender.frame.origin.x,// + sender.frame.width/2,
            y: sender.frame.height,//sender.frame.origin.y,// + sender.frame.height,
            width: 1,
            height: 1)
        presentViewController(vc, animated: true, completion: nil)
    }
    
    func presentSubjectID(){
        let vc = (self.storyboard?.instantiateViewControllerWithIdentifier("subjectID"))! as! subjectIDModalVC
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        self.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        self.modalPresentationStyle = .CurrentContext
        self.presentViewController(nav, animated: true, completion: nil)
    }
    
    func presentModalView(id:String){
        let nav = UINavigationController(rootViewController: (self.storyboard?.instantiateViewControllerWithIdentifier(id))!)
        self.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        self.modalPresentationStyle = .CurrentContext
        self.presentViewController(nav, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
}

