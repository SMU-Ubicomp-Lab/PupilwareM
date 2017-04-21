//
//  ACTModel.swift
//  Pupilware
//
//  Created by Xinyi Ding on 8/31/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

import Foundation
import GameplayKit

class ACTModel {
    
    static let sharedInstance = ACTModel()
    
    var currentQuestionIndex = 0
    
    var questions = [ ["actR1", "1"], ["actR2", "1"],["actR3", "1"],["actR4", "1"], //Reading
        ["act1", "1"], ["act2", "0"], ["act3", "1"], ["act4", "0"], ["act5", "1"],["act6", "0"], ["act7", "1"], //easy questions
        ["act22", "0"], ["act23", "1"], ["act24", "0"], ["act25", "1"], ["act32", "0"],["act37", "1"], ["act31", "1"], //medium questions
        ["act46", "0"], ["act50", "0"],["act51", "1"], ["act53","1"],["act54", "0"], ["act56", "0"], ["act59", "1"] // hard questions
    ]
   
    var permutation :[Int] = []
    var permutationIndex = 0
    
    var pseudoPermutation = [
        [0, 1, 2, 3, 7, 4, 6, 9, 5, 8, 10, 13, 14, 11, 12, 17, 15, 16, 24, 19, 20, 23, 18, 21, 22],
        [0, 1, 2, 3, 8, 9, 10, 4, 5, 6, 7, 13, 12, 15, 14, 17, 16, 11, 23, 22, 18, 24, 21, 19, 20],
        [0, 1, 2, 3, 10, 8, 4, 6, 7, 5, 9, 12, 16, 14, 13, 11, 15, 17, 23, 20, 21, 24, 19, 18, 22],
        [0, 1, 2, 3, 4, 8, 9, 10, 5, 7, 6, 11, 14, 13, 12, 15, 17, 16, 23, 20, 21, 24, 19, 18, 22],
        [0, 1, 2, 3, 10, 9, 4, 8, 5, 7, 6, 11, 14, 16, 15, 13, 17, 12, 23, 22, 24, 20, 18, 21, 19],
        [0, 1, 2, 3, 5, 10, 7, 9, 4, 8, 6, 11, 16, 15, 13, 12, 14, 17, 22, 20, 19, 23, 24, 21, 18],
        [0, 1, 2, 3, 10, 7, 5, 8, 9, 4, 6, 14, 17, 13, 11, 15, 16, 12, 19, 21, 20, 23, 18, 24, 22],
        [0, 1, 2, 3, 4, 9, 5, 6, 8, 10, 7, 16, 13, 14, 17, 11, 15, 12, 22, 20, 21, 23, 24, 19, 18],
        [0, 1, 2, 3, 4, 10, 6, 7, 9, 8, 5, 16, 15, 11, 12, 13, 14, 17, 21, 24, 18, 19, 23, 22, 20],
        [0, 1, 2, 3, 10, 8, 6, 7, 9, 5, 4, 15, 12, 11, 16, 17, 14, 13, 24, 18, 20, 19, 21, 23, 22],
        [0, 1, 2, 3, 4, 10, 5, 7, 9, 8, 6, 16, 13, 12, 15, 17, 11, 14, 20, 22, 21, 19, 18, 23, 24],
        [0, 1, 2, 3, 4, 6, 8, 10, 7, 5, 9, 14, 13, 16, 11, 17, 15, 12, 19, 23, 20, 21, 22, 24, 18],
        [0, 1, 2, 3, 8, 6, 9, 4, 5, 10, 7, 11, 12, 17, 15, 13, 14, 16, 21, 18, 24, 22, 19, 20, 23],
        [0, 1, 2, 3, 10, 5, 4, 8, 9, 6, 7, 16, 11, 15, 13, 12, 14, 17, 20, 23, 19, 21, 24, 22, 18],
        [0, 1, 2, 3, 6, 9, 10, 7, 4, 5, 8, 13, 12, 14, 17, 11, 16, 15, 18, 23, 24, 19, 21, 20, 22],
        [0, 1, 2, 3, 9, 10, 6, 4, 5, 8, 7, 16, 12, 13, 17, 15, 11, 14, 18, 23, 20, 21, 19, 22, 24],
        [0, 1, 2, 3, 9, 8, 4, 6, 5, 7, 10, 16, 13, 11, 17, 15, 14, 12, 24, 20, 19, 21, 18, 22, 23],
        [0, 1, 2, 3, 5, 4, 10, 8, 6, 9, 7, 15, 13, 12, 11, 16, 17, 14, 21, 19, 20, 23, 24, 22, 18],
        [0, 1, 2, 3, 5, 4, 7, 8, 9, 10, 6, 17, 13, 16, 15, 12, 11, 14, 24, 18, 22, 20, 21, 23, 19],
        [0, 1, 2, 3, 5, 4, 10, 8, 7, 6, 9, 17, 15, 12, 13, 14, 16, 11, 18, 20, 24, 19, 21, 23, 22],
        [0, 1, 2, 3, 10, 6, 9, 4, 7, 5, 8, 12, 14, 13, 11, 16, 15, 17, 21, 18, 23, 24, 20, 19, 22],
        [0, 1, 2, 3, 6, 10, 7, 9, 8, 5, 4, 16, 12, 13, 15, 11, 17, 14, 23, 24, 18, 19, 20, 22, 21],
        [0, 1, 2, 3, 9, 8, 4, 5, 7, 10, 6, 16, 12, 13, 15, 17, 11, 14, 22, 24, 20, 23, 18, 21, 19],
        [0, 1, 2, 3, 5, 6, 10, 9, 4, 7, 8, 15, 11, 13, 12, 16, 14, 17, 22, 18, 23, 20, 19, 21, 24],
        [0, 1, 2, 3, 4, 6, 7, 5, 8, 9, 10, 11, 16, 17, 14, 15, 13, 12, 24, 23, 22, 21, 20, 19, 18],
        [0, 1, 2, 3, 6, 9, 5, 4, 7, 10, 8, 16, 13, 11, 14, 12, 15, 17, 22, 23, 20, 24, 21, 19, 18],
        [0, 1, 2, 3, 6, 7, 8, 4, 10, 5, 9, 17, 11, 13, 15, 14, 16, 12, 24, 23, 22, 20, 21, 19, 18],
        [0, 1, 2, 3, 9, 8, 5, 6, 10, 4, 7, 12, 17, 11, 14, 16, 15, 13, 20, 18, 24, 22, 23, 19, 21],
        [0, 1, 2, 3, 7, 4, 6, 5, 8, 10, 9, 15, 11, 12, 17, 13, 16, 14, 21, 18, 24, 23, 22, 19, 20],
        [0, 1, 2, 3, 8, 6, 10, 9, 7, 5, 4, 13, 12, 11, 14, 16, 15, 17, 22, 21, 18, 19, 24, 20, 23]
    ]
    
    func setQuestions() {
        
        //Check if the app crashed, if crashed need to restore
        let defaults = NSUserDefaults.standardUserDefaults()
        let actQuestionIndex = defaults.integerForKey("actQuestionIndex")
        
        if actQuestionIndex != 0 {
            permutationIndex = defaults.integerForKey("actPermutationIndex")
            currentQuestionIndex = actQuestionIndex
            permutation = pseudoPermutation[permutationIndex]
        } else {
            //Use hard coded pesudo random
            var idx = Int(arc4random_uniform(31))
            permutation = pseudoPermutation[idx]
            permutationIndex = idx
            currentQuestionIndex = 0
            defaults.setInteger(idx, forKey: "actPermutationIndex")
            defaults.setInteger(currentQuestionIndex, forKey: "actQuestionIndex")
        }
    }
    
    func getInitQuestion() -> Array<String> {
        return questions[permutation[currentQuestionIndex]]
    }
    
    func getNextQuestion() -> Array<String> {
        
        if currentQuestionIndex + 1 < questions.count {
            currentQuestionIndex += 1
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setInteger(currentQuestionIndex, forKey: "actQuestionIndex")
            return questions[permutation[currentQuestionIndex]]
        } else {
            return []
        }
    }
    
    func getCurrentQuestionIndex() -> Int {
        return currentQuestionIndex
    }
    
    func getPermutationIndex() -> Int {
        return permutationIndex
    }
    
    func reset() {
        currentQuestionIndex = 0
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(currentQuestionIndex, forKey: "actQuestionIndex")
    }
    
    func getQuestionsNumber() -> Int {
        return questions.count 
    }
    
    func getPermutation() -> [Int] {
        return permutation
    }
    
    func getQuizId() -> Int {
        return permutation[currentQuestionIndex]
    }
}