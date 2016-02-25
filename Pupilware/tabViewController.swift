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
        if self.model.currentSubjectID == ""{
            self.presentSubjectID()
        }
        
        settingsCollection.allowsMultipleSelection = true
        containerView.layer.cornerRadius = 5
        expBlock.layer.cornerRadius = 5
        contTitle.text = "Welcome " + model.currentSubjectID
    }
    
    @IBAction func tapSettings(sender: AnyObject) {
        self.presentSettingsPopover(sender)
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
        model.currentTest = DigitTest(subjectID: model.currentSubjectID, digits: self.digitNum, iter: self.iter, lux: self.expSegment.titleForSegmentAtIndex(self.expSegment.selectedSegmentIndex)!, exact_lux: Double(UIScreen.mainScreen().brightness))
        self.presentDigitSpanModal()
    }
    
    @IBAction func shortPressCalibrate(sender: AnyObject) {
        self.presentCalibrationModal()
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
    
    func calibrationComplete(lum:Int){
        expBlock.hidden = true
    }
    
    func digitSpanTestComplete(lum:Int, digits:Int, iter:Int){
        model.completeTest(lum, digit: digits, iter: iter);
    }
    
    func presentLuxMeter(){
        self.dismissViewControllerAnimated(true, completion:nil)
        self.presentModalView("lux")
    }
    func presentAboutPage(){
        self.dismissViewControllerAnimated(true, completion:nil)
        
    }
    func presentAdminPage(){
        self.dismissViewControllerAnimated(true, completion:nil)
        self.presentModalView("admin")
    }
    
    //Collection View Delegate Functions________________________________
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let row = indexPath.row
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("header", forIndexPath: indexPath) as UICollectionViewCell
        cell.layer.borderColor = UIColor.blackColor().CGColor
        //cell.layer.borderWidth = 0.5
        cell.frame.size.width = self.settingsCollection.frame.width/4 - 10
        cell.frame.size.height = self.settingsCollection.frame.height/5
        let title = UILabel(frame: CGRectMake(0, 0, cell.bounds.size.width, 40))
        title.textAlignment = .Center
        cell.contentView.layer.backgroundColor = UIColor.whiteColor().CGColor
        cell.contentView.layer.cornerRadius = 5.0;
        let top = UIView(frame:CGRectMake(0,0,cell.bounds.size.width, 5))
        let bottom = UIView(frame:CGRectMake(0,cell.bounds.height-5,cell.bounds.size.width, 5))
        top.layer.backgroundColor = UIColor.whiteColor().CGColor
        bottom.layer.backgroundColor = UIColor.whiteColor().CGColor
        
        if (model.isTestComplete(self.expSegment.selectedSegmentIndex, digit: self.digitNum, iter: self.iter)){
            title.textColor = UIColor.greenColor()
        }else{
             title.textColor = UIColor.lightGrayColor()
        }
        
        if (row < 4){
            cell.contentView.layer.backgroundColor = UIColor.clearColor().CGColor
            title.text = String(indexPath.row + 5) + " Digits"
            title.font = UIFont.boldSystemFontOfSize(17)
        }else if (row < 8){
            title.text = String(row/4)
            cell.contentView.addSubview(bottom)
        }else if (row < 16){
            title.text = String(row/4)
            cell.contentView.addSubview(top)
            cell.contentView.addSubview(bottom)
        }else{
            title.text = String(row/4)
            cell.contentView.addSubview(top)
        }
        
        cell.frame.origin.x += 5
        cell.contentView.addSubview(title)
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: self.settingsCollection.frame.width/4 - 1,height: self.settingsCollection.frame.height/5 - 1);
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, 0, 0);
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0;
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        //self.settingsCollection.reloadData()
        if collectionView.indexPathsForSelectedItems()!.count > 1{
            for i in (0...(collectionView.indexPathsForSelectedItems()!.count - 1)){
                let prev = collectionView.cellForItemAtIndexPath(collectionView.indexPathsForSelectedItems()![i])
                prev!.selected = false
                for view in prev!.contentView.subviews  as [UIView]{
                    if let label = view as? UILabel {
                        if (model.isTestComplete(self.expSegment.selectedSegmentIndex, digit: self.digitNum, iter: self.iter)){
                             label.textColor = UIColor.greenColor()
                        }else{
                            label.textColor = UIColor.lightGrayColor()
                        }
                    }else{
                        //view.layer.backgroundColor = UIColor.whiteColor().CGColor
                    }
                }
            }
        }
    
        if indexPath.row < 4{
            return
        }else{
            if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
                //UPDATE MODEL
                for view in cell.contentView.subviews  as [UIView]{
                    if let label = view as? UILabel {
                        label.textColor = UIColor.blueColor()
                        self.iter = indexPath.row / 4 
                        self.digitNum = (indexPath.row % 4) + 5
                    }
                }
                cell.selected = true
                
                self.startButton.enabled = true
            }
            return
        }
    }
    
    //Helper functions___________________________________________________
    //(most of this is presentation boiler plate code)
    func presentDigitSpanModal(){
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("digitTest") as! expModalVC;
        vc.testName = String(self.digitNum) + " Digit: Iter " + String(self.iter) + " Test"
        vc.digits = self.digitNum
        vc.iter = self.iter
        vc.lum = self.expSegment.selectedSegmentIndex
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        self.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        self.modalPresentationStyle = .CurrentContext
        self.presentViewController(nav, animated: true, completion: nil)
    }
    
    func presentCalibrationModal(){
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("calibrate") as! calModalVC;
        vc.testName = "Lum " + String(expSegment.selectedSegmentIndex + 1) + ": Calibration"
        vc.lum = expSegment.selectedSegmentIndex + 1
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
