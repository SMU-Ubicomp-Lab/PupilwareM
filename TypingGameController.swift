//
//  TypingGameController.swift
//  funTyping
//
//  Created by Chatchai Wangwiwattana on 2/8/17.
//  Copyright © 2017 Chatchai Wangwiwattana. All rights reserved.
//

import Foundation



/*! -----------------------------------------------
 *  \brief: This game states will sent out events to UI
 */
protocol TypingGameProtocol {
    func onGameStarted()
    func onNextLevel()
    func onGameEnded()
}



/*! -----------------------------------------------
 *  \brief: This manages the Typing Game.
 *          It controls game logic from start to finish.
 */
class TypingGameController{
    
    var lessonSets      = [""]
    
    var currentLesson   = 0
    var currentLocation = 0
    var mistakes        = 0
    
    var key             = ""
    
    var gameEvent:TypingGameProtocol?
    
    
    init(){
        print( "game object is created" )
    }
    
    
    /*! -----------------------------------------------
     *  \brief reset game state variables
     */
    func initGame(){
        
        /*! init game state */
        currentLesson   = 0
        currentLocation = 0
        mistakes        = 0
        
        lessonSets = ["default game level, something went wrong on loading a real game level"]
        
        loadGameLevels()
        
        print( "init game" )
        
        gameEvent?.onGameStarted()
        
    }
    
    
    /*! -----------------------------------------------
     *  \brief: load game level file to game controller
     */
    func loadGameLevels(){
        
        let url = NSBundle.mainBundle().URLForResource("gameLevel", withExtension: "json")
        let data = NSData(contentsOfURL: url!)
        
        do {
            
            let object = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
            if let dictionary = object as? [String: AnyObject] {
                
                guard let levels = dictionary["GameLevels"] as? [String] else { return }
                self.lessonSets = levels
                
            }
            
        } catch {
            // Handle Error
            print("Error parsing JSON file")
        }
    }
    
    
    /*! -----------------------------------------------
     *  \brief store input, so the game can update
     */
    func input(key:String){
    
        self.key = key;
        
    }
    
    
    /*! -----------------------------------------------
     *  \brief Update game state
     */
    func update(){
        if(self.key == String(self.lessonSets[self.currentLesson][self.currentLocation])){
            
            if(self.currentLocation < self.lessonSets[self.currentLesson].characters.count-1 )
            {
                self.currentLocation += 1
            }
            else
            {
                if(self.currentLesson < self.lessonSets.count-1){
                    self.currentLocation = 0
                    self.currentLesson += 1
                    print("Next lesson \(self.currentLesson)")
                    gameEvent?.onNextLevel()
                }
                else
                {
                    self.currentLesson = self.lessonSets.count-1
                    print("Done")
                    gameEvent?.onGameEnded()
                }
                
            }
        }
        else{
            self.mistakes += 1
        }
    }
    
    
    /*! -----------------------------------------------
     *  \brief distroy game state
     */
    func exit(){
        print("exit game, clear vairables")
    }
    
}