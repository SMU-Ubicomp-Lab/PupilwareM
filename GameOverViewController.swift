//
//  GameOverViewController.swift
//  funTyping
//
//  Created by Chatchai Wangwiwattana on 2/8/17.
//  Copyright © 2017 Chatchai Wangwiwattana. All rights reserved.
//

import UIKit


class GameOverViewController: UIViewController {
  
    
    var gameCtrl:TypingGameController?
    
    
    @IBOutlet weak var missLabel: UILabel!


    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        self.gameCtrl = appDelegate.gameCtrl

    }

    
    override func viewWillAppear(animated: Bool) {
        updateUI()
    }

    
    override func viewWillDisappear(animated: Bool) {
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func updateUI(){
        self.missLabel.text! = "You miss \(self.gameCtrl!.mistakes) times"
    }
    
    
}

