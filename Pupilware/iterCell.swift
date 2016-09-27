//
//  iterCell.swift
//  Pupilware
//
//  Created by Raymond Martin on 2/25/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

import Foundation
import UIKit

class iterCell: UICollectionViewCell{
    @IBOutlet weak var label: UILabel!
    var header = false
    var digit = -1
    var iter = -1
    
    convenience override init(frame: CGRect) {
        self.init(frame: frame)
    }
    
    func resetCell(){
        self.layer.borderColor = UIColor.blackColor().CGColor
        self.layer.borderWidth = 0.0
        self.layer.cornerRadius = 5.0
        
        if(!header){
            self.layer.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5).CGColor
            self.label.font = UIFont.systemFontOfSize(20)
        }else{
            self.layer.backgroundColor = UIColor.clearColor().CGColor
            self.label.font = UIFont.boldSystemFontOfSize(17)
        }
    }
    
    func setDone(){
        if (!header){
            self.layer.backgroundColor = UIColor.greenColor().colorWithAlphaComponent(0.5).CGColor
        }
    }
    
    func setSelected(){
        if (!header){
            self.layer.borderWidth = 5.0
        }
    }
}
