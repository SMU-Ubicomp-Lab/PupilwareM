//
//  ViewController.swift
//  funTyping
//
//  Created by Chatchai Wangwiwattana on 2/8/17.
//  Copyright © 2017 Chatchai Wangwiwattana. All rights reserved.
//

import UIKit




class MainGameViewController: UIViewController, TypingGameProtocol, BridgeDelegate {
    
    @IBOutlet weak var typingCanvas: UILabel!
    @IBOutlet weak var mistakeLabel: UILabel!
    
    // require for Data Model
    let model = DataModel.sharedInstance
    var testFinished = false
    //---------------------------
    
    var keys = [UIKeyCommand]()
    
    let myAttribute = [NSBackgroundColorAttributeName: UIColor.greenColor()]
    var myAttrString = NSMutableAttributedString(string:"")
    
    var gameCtrl:TypingGameController?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register key events
        for digit in "abcdefghijklmnopqrstuvwxyz .';,".characters
        {
            keys.append(UIKeyCommand(input: String(digit), modifierFlags: [], action:  #selector(MainGameViewController.keyPressed(_:))))
        }
        
        self.model.bridgeDelegate = self
        
        
        // Get game controller object
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        self.gameCtrl = appDelegate.gameCtrl
        self.gameCtrl!.gameEvent = self
        
    }
    
    
    
    func updateUI()
    {
        
        let myRange = NSRange(location:gameCtrl!.currentLocation, length: 1)
        
        myAttrString.setAttributedString(NSAttributedString(string:gameCtrl!.lessonSets[gameCtrl!.currentLesson]))
        myAttrString.addAttributes(myAttribute, range:myRange)
        
        // update UI
        self.typingCanvas.attributedText = myAttrString
        self.mistakeLabel.text = "Mistakes \(gameCtrl!.mistakes)"
    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        
        self.testFinished = false
        self.model.currentTest = TypingTest(subjectID: self.model.currentSubjectID)
        
        gameCtrl!.initGame()
        updateUI()
        
    }
    
    
    
    override func viewWillDisappear(animated: Bool) {
        gameCtrl!.exit()
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    
    
    
    override var keyCommands: [UIKeyCommand]?{
        return keys
    }
    
    
    
    
    func keyPressed(command: UIKeyCommand) {
        
        gameCtrl!.input(command.input)
        gameCtrl!.update()
        updateUI()
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
        
    }
    func faceNotInView(){
        
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
    
    
//------- Game Controller Events-----------------------------------
    
    func onGameStarted() {
        print("UI game starated recived")
        updateUI()
    }
    
    
    func onGameEnded() {
        print("Game ended received")
        
        // Tell pupilware to stop system.
        self.model.inTest = false
        self.testFinished = true;
        //-----------------------------
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let vc : UIViewController = mainStoryboard.instantiateViewControllerWithIdentifier("gameOverVC") as UIViewController
//        self.presentViewController(vc, animated: true, completion: nil)
        
        self.navigationController!.pushViewController(vc, animated: true)
    
        
    }
    
    
    func onNextLevel() {
        print("next level recived")
    }
    
}

