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
    var questionsEasy = [["act1", "1"], ["act2", "0"], ["act3", "1"], ["act4", "0"], ["act5", "1"],
                         ["act6", "0"], ["act7", "1"], ["act8", "0"], ["act9", "1"], ["act10","0"],
                         ["act11", "1"], ["act12", "0"], ["act13", "1"], ["act14", "0"], ["act15","1"]]
    
    var questionsMedium = [["act16", "0"], ["act17", "1"], ["act18", "0"], ["act19", "1"], ["act20", "0"],
                           ["act21", "1"], ["act22", "0"], ["act23", "1"], ["act24", "0"], ["act25","1"],
                           ["act26", "0"], ["act27", "1"], ["act28", "0"], ["act29", "1"], ["act30","0"]]
    
    var questionsHard = [["act31", "1"], ["act32", "0"]]
    
    var questions: [[String]] = []
    
    var permutationEasy = Array(0...14)
    var permutationMedium = Array(15...31)
    var permutationHard = Array(32...33)
    var permutation :[Int] = []
    
    func shuffelQuestions() {
        
        let shuffledEasy = GKRandomSource.sharedRandom().arrayByShufflingObjectsInArray(permutationEasy) as! [Int]
        let shuffledMedium = GKRandomSource.sharedRandom().arrayByShufflingObjectsInArray(permutationMedium) as! [Int]
        let shuffledHard = GKRandomSource.sharedRandom().arrayByShufflingObjectsInArray(permutationHard) as! [Int]
        
        questions = questionsEasy + questionsMedium + questionsHard
        permutation = shuffledEasy + shuffledMedium + shuffledHard
    }
    
    func getInitQuestion() -> Array<String> {
        return questions[permutation[currentQuestionIndex]]
    }
    
    func getNextQuestion() -> Array<String> {
        
        if currentQuestionIndex + 1 < questions.count {
            currentQuestionIndex += 1
            return questions[permutation[currentQuestionIndex]]
        } else {
            return []
        }
    }
    
    func getCurrentQuestionIndex() -> Int {
        return currentQuestionIndex
    }
    
    func getPermutationIndex() -> Int {
        return permutation[currentQuestionIndex]
    }
    
    func reset() {
        currentQuestionIndex = 0
    }
    
    func getQuestionsNumber() -> Int {
        return questions.count 
    }
    
    func getPermutation() -> [Int] {
        return permutation
    }
}