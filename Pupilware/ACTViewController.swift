//
//  ACTViewController.swift
//  Pupilware
//
//  Created by Xinyi Ding on 8/28/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

import Foundation
import UIKit


class ACTViewController: UIViewController, BridgeDelegate {
    
    var start: CGPoint?
    let questionsModle = ACTModel.sharedInstance
    let model = DataModel.sharedInstance
    
    var delegate:sendBackDelegate?
    var testFinished = false
    
    var currentQuestionIndex = 0
    var currentQuestion: Array<String> = []
    var currentOptions = []
    var totalQuestions = 0
    var participantId = ""
    var participantAnswers = [String](count: 9, repeatedValue: "")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.model.bridgeDelegate = self
        
        
        self.questionLabel.layer.borderColor = UIColor.blackColor().CGColor
        self.questionLabel.layer.borderWidth = 1
        submitButton.hidden = true
        participantId = model.currentSubjectID
        questionsModle.reset()
        questionLabel.font = questionLabel.font.fontWithSize(20)
        questionsModle.shuffelQuestions()
        totalQuestions = questionsModle.getQuestionsNumber()
        currentQuestionIndex = questionsModle.getCurrentQuestionIndex()
        currentQuestion = questionsModle.getInitQuestion()
        self.updateQuestion()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        // Add new test to the Data Model,
        // Pupilware will get these file name from it. :P
        self.model.inTest = true
        self.model.currentTest = ACTTest(subjectID: self.model.currentSubjectID, itemID: currentQuestionIndex)
        
    }
    //-----------------------------------------------------
    // Bridge Delegation Func
    //
    
    func trackingFaceDone(){
        
    }
    func startTrackingFace(){
        
    }
    func finishCalibration(){
    
    }
    
    @IBOutlet weak var faceLabel: UILabel!
    
    func faceInView(){
        faceLabel.text = ""
    }
    func faceNotInView(){
        faceLabel.text = "Keep Face in View"
    }
    
    func isNumberStarted() -> Bool{
        return false;
    }
    func isNumberStoped() -> Bool{
        return false;
    }
    
    func isTestingFinished() -> Bool{
        return self.testFinished;
    }
    
    //-----------------------------------------------------
    
    @IBOutlet weak var drawImageView: UIImageView!
    
    @IBAction func clearImage(sender: UIButton) {
        drawImageView.image = UIImage.init(named: "notepad.png")    }
    
    @IBOutlet weak var questionLabel: UILabel!
    
    @IBOutlet weak var answerA: UIButton!
    
    @IBOutlet weak var answerB: UIButton!
    
    @IBOutlet weak var answerC: UIButton!
    
    @IBOutlet weak var answerD: UIButton!
    
    @IBOutlet weak var answerE: UIButton!
    
    @IBAction func answerAclicked(sender: UIButton) {
        sender.backgroundColor = UIColor.lightGrayColor()
        answerB.backgroundColor = nil
        answerC.backgroundColor = nil
        answerD.backgroundColor = nil
        answerE.backgroundColor = nil
        
        participantAnswers[currentQuestionIndex] = "A"
    }
    
    @IBAction func answerBclicked(sender: UIButton) {
        sender.backgroundColor = UIColor.lightGrayColor()
        answerA.backgroundColor = nil
        answerC.backgroundColor = nil
        answerD.backgroundColor = nil
        answerE.backgroundColor = nil
        
        participantAnswers[currentQuestionIndex] = "B"
       
    }
    
    @IBAction func answerCclicked(sender: UIButton) {
        sender.backgroundColor = UIColor.lightGrayColor()
        answerA.backgroundColor = nil
        answerB.backgroundColor = nil
        answerD.backgroundColor = nil
        answerE.backgroundColor = nil
        
        participantAnswers[currentQuestionIndex] = "C"
    }
    
    @IBAction func answerDclicked(sender: UIButton) {
        sender.backgroundColor = UIColor.lightGrayColor()
        answerA.backgroundColor = nil
        answerB.backgroundColor = nil
        answerC.backgroundColor = nil
        answerE.backgroundColor = nil
        
        participantAnswers[currentQuestionIndex] = "D"
    }
    
    @IBAction func answerEclicked(sender: UIButton) {
        sender.backgroundColor = UIColor.lightGrayColor()
        answerA.backgroundColor = nil
        answerB.backgroundColor = nil
        answerC.backgroundColor = nil
        answerD.backgroundColor = nil
        
        participantAnswers[currentQuestionIndex] = "E"
    }
    
    @IBAction func submitTest(sender: UIButton) {
        saveData()
        let alertController = UIAlertController(title: "ACT TEST", message:
            "Test submitted, Thank you", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
        // Tell pupilware to stop system.
        self.model.inTest = false
        self.testFinished = true;
        
    }
    
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    
    @IBAction func getNext(sender: UIButton) {
        currentQuestion = questionsModle.getNextQuestion()
        self.updateQuestion()
        self.presentSurveyModal()
    }
    
    func updateQuestion() {
        questionLabel.text = currentQuestion[0]
        answerA.setTitle(currentQuestion[1], forState: UIControlState.Normal)
        answerB.setTitle(currentQuestion[2], forState: UIControlState.Normal)
        answerC.setTitle(currentQuestion[3], forState: UIControlState.Normal)
        answerD.setTitle(currentQuestion[4], forState: UIControlState.Normal)
        answerE.setTitle(currentQuestion[5], forState: UIControlState.Normal)
        currentQuestionIndex = questionsModle.getCurrentQuestionIndex()
        var selected = ""

        selected = participantAnswers[currentQuestionIndex]
        
        switch selected {
        case "A":
            answerA.backgroundColor = UIColor.lightGrayColor()
            answerB.backgroundColor = nil
            answerC.backgroundColor = nil
            answerD.backgroundColor = nil
            answerE.backgroundColor = nil
            break
        case "B":
            answerA.backgroundColor = nil
            answerB.backgroundColor = UIColor.lightGrayColor()
            answerC.backgroundColor = nil
            answerD.backgroundColor = nil
            answerE.backgroundColor = nil
            break
        case "C":
            answerA.backgroundColor = nil
            answerB.backgroundColor = nil
            answerC.backgroundColor = UIColor.lightGrayColor()
            answerD.backgroundColor = nil
            answerE.backgroundColor = nil
            break
        case "D":
            answerA.backgroundColor = nil
            answerB.backgroundColor = nil
            answerC.backgroundColor = nil
            answerD.backgroundColor = UIColor.lightGrayColor()
            answerE.backgroundColor = nil
            break
        case "E":
            answerA.backgroundColor = nil
            answerB.backgroundColor = nil
            answerC.backgroundColor = nil
            answerD.backgroundColor = nil
            answerE.backgroundColor = UIColor.lightGrayColor()
            break
        default:
            answerA.backgroundColor = nil
            answerB.backgroundColor = nil
            answerC.backgroundColor = nil
            answerD.backgroundColor = nil
            answerE.backgroundColor = nil
        }
    
        if currentQuestionIndex ==  totalQuestions - 1 {
            nextButton.enabled = false
            submitButton.hidden = false
        } else {
            nextButton.enabled = true
        }
    }
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first as UITouch!
        start = touch.locationInView(self.drawImageView)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first as UITouch!
        let end = touch.locationInView(self.drawImageView)
        if let s = self.start {
            draw(s, end: end)
        }
        self.start = end
    }
    
    func draw(start: CGPoint, end: CGPoint) {
        UIGraphicsBeginImageContext(self.drawImageView.frame.size)
        
        let context = UIGraphicsGetCurrentContext()
        drawImageView?.image?.drawInRect(CGRect(x:0, y:0, width: drawImageView.frame.width, height: drawImageView.frame.height))
        CGContextSetLineWidth(context!, 6)
        CGContextBeginPath(context!)
        CGContextMoveToPoint(context!, start.x, start.y)
        CGContextAddLineToPoint(context!, end.x, end.y)
        CGContextStrokePath(context!)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        drawImageView.image = newImage
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    func writeToCSV(fileName: String, row: String) {
        let data = row.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        
        if NSFileManager.defaultManager().fileExistsAtPath(fileName) {
            print("writing to " + fileName)
            if let fileHandle = NSFileHandle(forUpdatingAtPath: fileName) {
                fileHandle.seekToEndOfFile()
                fileHandle.writeData(data)
                fileHandle.closeFile()
            }
            else {
                print("Can't open fileHandle")
            }
        }
        else {
            NSFileManager.defaultManager().createFileAtPath(fileName, contents: nil, attributes: nil)
            print("File not exist")
            print("created" + fileName)
            if let fileHandle = NSFileHandle(forUpdatingAtPath: fileName) {
                fileHandle.seekToEndOfFile()
                fileHandle.writeData(data)
                fileHandle.closeFile()
            }
            else {
                print("Can't open fileHandle")
            }
        }
    }
    
    func saveData() {
        let filePath = getDocumentsDirectory().stringByAppendingPathComponent(model.currentSubjectID + "_ACT_Answers.txt")
        let stringAnswers = participantAnswers.joinWithSeparator(",")
        let tmpPermutation = questionsModle.getPermutation()
        let strPermutation = tmpPermutation.map
            {
                String($0)
        }
        let stringPermutation = strPermutation.joinWithSeparator(",")
        writeToCSV(filePath, row: stringAnswers + stringPermutation )
    }
    
    func presentSurveyModal(){
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("surveyView") as! SurveyViewController;
        // let nav = UINavigationController(rootViewController: vc)
        vc.quizId = currentQuestionIndex
        self.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        self.modalPresentationStyle = .CurrentContext
        self.presentViewController(vc, animated: true, completion: nil)
    }
}
