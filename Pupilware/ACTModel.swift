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
    var questions = [
        ["Question #1. For all real numbers b and c such that the product of c and 3 is b, which of the following expressions represents the sum of c and 3 in terms of b?","A.  b + 3", "B. 3b + 3", "C. 3(b +3)", "D. (b+3)/3", "E. b/3 + 3","0", "1"],
        ["Question #2. For all real numbers b and c such that the product of c and 3 is b, which of the following expressions represents the sum of c and 3 in terms of b?","A.  b + 3", "B. 3b + 3", "C. 3(b +3)", "D. (b+3)/3", "E. b/3 + 3", "1", "1"],
        ["Question #3. For all real numbers b and c such that the product of c and 3 is b, which of the following expressions represents the sum of c and 3 in terms of b?","A.  b + 3", "B. 3b + 3", "C. 3(b +3)", "D. (b+3)/3", "E. b/3 + 3", "2", "1"],
        ["Question #4. For all real numbers b and c such that the product of c and 3 is b, which of the following expressions represents the sum of c and 3 in terms of b?","A.  b + 3", "B. 3b + 3", "C. 3(b +3)", "D. (b+3)/3", "E. b/3 + 3", "3", "2"],
        ["Question #5. For all real numbers b and c such that the product of c and 3 is b, which of the following expressions represents the sum of c and 3 in terms of b?","A.  b + 3", "B. 3b + 3", "C. 3(b +3)", "D. (b+3)/3", "E. b/3 + 3", "4","2"],
        ["Question #6. A box contains 7 blu marbles, 4 red marbles and 6 green marbles. How many additional blue marbles must be added in the box so that the probability of randomly drawing a blue marble is 1/2?","A. 2", "B. 3", "C. 4", "D. 5", "E.6", "5", "2"],
        ["Question #7. An integer from 100 through 999, inclusive, is to be chosen at random. What is the probability that the number choosen will have 0 as at least 1 digit? ","A. 19/900", "B. 81/900", "C. 90/900", "D. 171/900", "E. 271/1000", "6", "3"],
        ["Question #8. For all x in the domain of the function (x+1)/(x^3 - x), this function is equivalent to","A. 1/x^2 - 1/x^3", "B. 1/x^3 - 1/x", "C. 1/(x^2 - 1)", "D. 1/(x^2 - x)", "E. 1/ x^3", "7", "3"],
        ["Questions #9. For a project in Home Economics class, Kirk is making a tablecloth for a circular table 3 feet in diameter. The finished tablecloth needs to hang down 5 inches over the edge of the table all the way around. To finish the edge of the tablecloth, Kirk will fold under and sew down 1 inch of the material all around the edge. Kirk is going to use a single piece of rectangular fabric that is 60 inches wide. What is the shortest lentgh of the fabric, in inches, Kirk could use to make the tablecloth without putting any separate pieces of fabric together? ","A. 15", "B. 24", "C. 30", "D. 42", "E. 48", "8", "3"]
    ]
    var permutationEasy :[Int] = [0, 1, 2]
    var permutationMedium :[Int] = [3, 4, 5]
    var permutationHard :[Int] = [6, 7, 8]
    var permutation :[Int] = []
    
    func shuffelQuestions() {
        let shuffledEasy = GKRandomSource.sharedRandom().arrayByShufflingObjectsInArray(permutationEasy) as! [Int]
        let shuffledMedium = GKRandomSource.sharedRandom().arrayByShufflingObjectsInArray(permutationMedium) as! [Int]
        let shuffledHard = GKRandomSource.sharedRandom().arrayByShufflingObjectsInArray(permutationHard) as! [Int]
        
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