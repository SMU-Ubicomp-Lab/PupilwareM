//
//  iterCell.swift
//  Pupilware
//
//  Created by Raymond Martin on 2/25/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

import Foundation
import UIKit

class iterCell: UICollectionViewCell{
    @IBOutlet weak var label: UILabel!
    var header = false
    var digit = -1
    var iter = -1
    
    convenience override init (frame: CGRect){
        self.init(frame: frame)
        //self.collectionElement = passedCollectionElement
    }
    
}
