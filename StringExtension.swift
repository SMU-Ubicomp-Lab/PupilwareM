//
//  StringExtension.swift
//  funTyping
//
//  Created by Chatchai Wangwiwattana on 2/9/17.
//  Copyright © 2017 Chatchai Wangwiwattana. All rights reserved.
//

import Foundation

extension String {
    
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = startIndex.advancedBy(r.startIndex)
        let end = start.advancedBy(r.endIndex - r.startIndex)
        return self[Range(start ..< end)]
    }
}