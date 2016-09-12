//
//  tabViewController.swift
//  Pupilware
//
//  Created by Raymond Martin on 1/29/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

import Foundation
import UIKit

class tabViewController: UIViewController, UIPopoverPresentationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, sendBackDelegate{
    let model = DataModel.sharedInstance
    let tobiiGlass = TobiiGlass.sharedInstance
    @IBOutlet weak var expSegment: UISegmentedControl!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var settingsCollection: UICollectionView!
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var contTitle: UILabel!
    @IBOutlet weak var expBlock: UIView!
    var digitNum = 5
    var iter = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (self.model.currentSubjectID == ""){
            self.presentSubjectID()
        }
        
        //self.expBlock.hidden = true
        
        self.settingsCollection.allowsMultipleSelection = true
        self.containerView.layer.cornerRadius = 5
        self.expBlock.layer.cornerRadius = 5
        self.contTitle.text = "Welcome " + model.currentSubjectID
    }
    
    @IBAction func tapSettings(sender: AnyObject) {
        self.presentSettingsPopover(sender)
    }
    
    @IBAction func lumChanged(sender: AnyObject) {
        self.settingsCollection.reloadData()
        self.expBlock.hidden = false
    }
    
    @IBAction func changeLightingSegment(sender: AnyObject) {
        switch expSegment.selectedSegmentIndex{
        case 0:
            print("dimmest")
        case 1:
            print("dim")
        case 2:
            print("nuetral")
        case 3:
            print("bright")
        case 4:
            print("brightest")
        default:
            break
        }
    }

    @IBAction func startDigitTest(sender: AnyObject) {
        //settup test settings
        if (model.lumMode){
            model.currentTest = DigitTest(subjectID: model.currentSubjectID, digits: self.digitNum, iter: self.iter, lux: self.expSegment.selectedSegmentIndex+1, exact_lux: Double(UIScreen.mainScreen().brightness))
        }else{
            model.currentTest = DigitTest(subjectID: model.currentSubjectID, digits: self.digitNum, iter: self.iter, angle: self.expSegment.selectedSegmentIndex+1, exact_lux: Double(UIScreen.mainScreen().brightness))
        }
        self.tobiiGlass.createRecording(self.model.tobiiSubjectIds[self.model.currentSubjectID]!)
        self.presentDigitSpanModal()
    }
    
    @IBAction func shortPressCalibrate(sender: AnyObject) {
        //self.tobiiGlass.createCalibration(self.model.tobiiProject, participantId: self.model.tobiiCurrentParticipant)
        self.tobiiGlass.createRecording(self.model.tobiiSubjectIds[self.model.currentSubjectID]!)
        self.presentCalibrationModal()
    }
    
    @IBAction func calibrateGlass(sender: AnyObject) {
        self.presentCalibrationGlassModal()
    }

    func checkStartButton(){
        if self.model.digitIteration > 0{
            self.startButton.enabled = true
        }
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
        self.tobiiGlass.stopRecording(self.model.tobiiCurrentRecording)
        
        //Check Tobii Glass calibration status, if failed, re calibrate
        //self.tobiiGlass.checkCalibration(self.model.tobiiCurrentCalibration)
        
    }
    
    func digitSpanTestComplete(){
        print(model.digitTestLumProgress)
        model.currentTest?.completeTest()
        model.currentTest = nil
        print(model.digitTestLumProgress)
        self.settingsCollection.reloadData()
        self.tobiiGlass.stopRecording(self.model.tobiiCurrentRecording)
    }
    
    func presentLuxMeter(){
        self.dismissViewControllerAnimated(true, completion:nil)
        self.presentModalView("lux")
    }
    
    func switchModes(){
        self.dismissViewControllerAnimated(true, completion:nil)
        model.lumMode = !model.lumMode
        if (model.lumMode){
            self.expSegment.setTitle("Lum 1", forSegmentAtIndex: 0)
            self.expSegment.setTitle("Lum 2", forSegmentAtIndex: 1)
            self.expSegment.setTitle("Lum 3", forSegmentAtIndex: 2)
            self.expSegment.setTitle("Lum 4", forSegmentAtIndex: 3)
            self.expSegment.setTitle("Lum 5", forSegmentAtIndex: 4)
        }else{
            self.expSegment.setTitle("Angle 1", forSegmentAtIndex: 0)
            self.expSegment.setTitle("Angle 2", forSegmentAtIndex: 1)
            self.expSegment.setTitle("Angle 3", forSegmentAtIndex: 2)
            self.expSegment.setTitle("Angle 4", forSegmentAtIndex: 3)
            self.expSegment.setTitle("Angle 5", forSegmentAtIndex: 4)
        }
        
        self.settingsCollection.reloadData()
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
        return 16
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell:iterCell = collectionView.dequeueReusableCellWithReuseIdentifier("header", forIndexPath: indexPath) as! iterCell
        cell.frame.size.width = self.settingsCollection.frame.width/4 - 10
        cell.frame.size.height = self.settingsCollection.frame.height/4 - 10
        cell.digit = (indexPath.row%4) + 5
        cell.iter = indexPath.row/4
        
        if (cell.iter == 0){
            cell.header = true
            cell.label.text = String(indexPath.row + 5) + " Digits"
        }else{
            cell.header = false
            cell.label.text = String(cell.iter)
        }
        
        cell.resetCell()
        
        if (!cell.header && model.isDigitTestComplete(self.expSegment.selectedSegmentIndex, digit: cell.digit, iter: cell.iter)){
            cell.setDone()
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: self.settingsCollection.frame.width/4 - 10,height: self.settingsCollection.frame.height/4 - 10);
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
            if (!cell.header && model.isDigitTestComplete(self.expSegment.selectedSegmentIndex, digit: cell.digit, iter: cell.iter)){
                cell.setDone()
            }
        }
    
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! iterCell
        if (cell.header){
            return
        }else{
            cell.setSelected()
            self.iter = cell.iter
            self.digitNum = cell.digit
            self.startButton.enabled = true
        }
    }
    
    //Helper functions___________________________________________________
    //(most of this is presentation boiler plate code)
    func presentDigitSpanModal(){
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("digitTest") as! expModalVC;
        vc.testName = String(self.digitNum) + " Digit: Iter " + String(self.iter) + " Test"
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        self.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        self.modalPresentationStyle = .CurrentContext
        self.presentViewController(nav, animated: true, completion: nil)
    }
    
    func presentCalibrationModal(){
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("calibrate") as! calModalVC;
        vc.testName =   self.expSegment.titleForSegmentAtIndex(self.expSegment.selectedSegmentIndex)! + ": Calibration"
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        self.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        self.modalPresentationStyle = .CurrentContext
        self.presentViewController(nav, animated: true, completion: nil)
    }
    
    func presentCalibrationGlassModal(){
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("calibrateGlass") as! CalibrateGlassViewController;
       // let nav = UINavigationController(rootViewController: vc)
        self.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        self.modalPresentationStyle = .CurrentContext
        self.presentViewController(vc, animated: true, completion: nil)
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
