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
    
    func setDone(){
        if (!header){
            self.contentView.layer.backgroundColor = UIColor.greenColor().colorWithAlphaComponent(0.5).CGColor
            self.layer.cornerRadius = 5.0
        }
        
        label.font = label.font.fontWithSize(20)
        
    }
    
    func setSelected(){
        if (!header){
            self.layer.borderColor = UIColor.blackColor().CGColor
            self.layer.cornerRadius = 5.0
            self.layer.borderWidth = 5.0
        }
    }
    
    func clearContent(){
        if (!header){
            self.layer.borderWidth = 0.0
            self.layer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5).CGColor
        }else{
            self.layer.backgroundColor = UIColor.clearColor().CGColor
        }
    }
    
    func reset(){
        if (!header){
            self.layer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5).CGColor
            self.layer.cornerRadius = 5.0
            self.layer.borderWidth = 0.0
        }
        
        label.font = label.font.fontWithSize(20)
    }
    
}
