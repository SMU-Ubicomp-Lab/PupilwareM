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
                         ["act6", "0"], ["act7", "1"]]
    
    var questionsMedium = [["act22", "0"], ["act23", "1"], ["act24", "0"], ["act25", "1"], ["act32", "0"],
                           ["act37", "1"], ["act31", "1"]]
    
    var questionsHard = [["act46", "0"], ["act50", "0"],["act51", "1"], ["act53","1"],
                         ["act54", "0"], ["act56", "0"], ["act59", "1"]]
    

    
    
    var readingQuestion = [["actR1", "1"], ["actR2", "1"],["actR3", "1"],["actR4", "1"]]
    
    var questions: [[String]] = []
    
    var permutationEasy = Array(4...10)
    var permutationMedium = Array(11...17)
    var permutationHard = Array(18...24)
    var permutation :[Int] = []
    
    func shuffelQuestions() {
        
        let shuffledEasy = GKRandomSource.sharedRandom().arrayByShufflingObjectsInArray(permutationEasy) as! [Int]
        let shuffledMedium = GKRandomSource.sharedRandom().arrayByShufflingObjectsInArray(permutationMedium) as! [Int]
        let shuffledHard = GKRandomSource.sharedRandom().arrayByShufflingObjectsInArray(permutationHard) as! [Int]
        
        questions = readingQuestion + questionsEasy + questionsMedium + questionsHard
        permutation = Array(0...3) + shuffledEasy + shuffledMedium + shuffledHard
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