//
//  StepSlider.swift
//  Allergistic
//
//  Created by Chris Forant on 4/29/16.
//  Copyright © 2016 Totem. All rights reserved.
//

import UIKit

@IBDesignable
public class StepSlider: UISlider {
    
    // Inspectables
    @IBInspectable public var steps: Int = 5 {
        didSet { maximumValue = Float(steps - 1) }
    }
    @IBInspectable public var minValue: Float = 0.0 {
        didSet { minimumValue = minValue }
    }
    @IBInspectable public var maxValue: Float = 4.0 {
        didSet { maximumValue = maxValue }
    }
    @IBInspectable public var customTrack: Bool = false
    @IBInspectable public var trackHeight: Int = 3
    @IBInspectable public var trackColor: UIColor = UIColor.lightGrayColor()
    @IBInspectable public var stepTickWidth: Int = 2
    @IBInspectable public var stepTickHeight: Double = 8
    @IBInspectable public var stepTickColor: UIColor = UIColor.lightGrayColor()
    @IBInspectable public var stepTickRounded: Bool = false
    
    // Computeds
    var stepWidth: Double {
        return Double(trackWidth) / (Double(steps - 1))
    }
    var thumbRect: CGRect {
        let trackRect = trackRectForBounds(bounds)
        return thumbRectForBounds(bounds, trackRect: trackRect, value: value)
    }
    var trackWidth: CGFloat {
        return self.bounds.size.width - thumbRect.width
    }
    var trackOffset: CGFloat {
        return (self.bounds.size.width - self.trackWidth) / 2
    }
    
    // Properties for handling touch
    var previousLocation = CGPointZero
    var dragging = false
    var originalValue: Int = 0
    
    // Methods
    override public func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override public func drawRect(rect: CGRect) {
        super.drawRect(rect)
        drawTrack()
    }
    
    func drawTrack() {
        
        let ctx = UIGraphicsGetCurrentContext()
        CGContextSaveGState(ctx)
        
        // Remove the original track if custom
        if customTrack {
            
            // Clear original track using a transparent pixel
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), false, 0.0)
            let transparentImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            setMaximumTrackImage(transparentImage, forState: .Normal)
            setMinimumTrackImage(transparentImage, forState: .Normal)
            
            // Draw custom track
            CGContextSetFillColorWithColor(ctx, trackColor.CGColor)
            let x = trackOffset
            let y = Int((bounds.height / 2)) - (trackHeight / 2)
            let trackPath = UIBezierPath(rect: CGRect(x: Int(x), y: y, width: Int(bounds.width - (trackOffset * 2)), height: trackHeight))
            
            CGContextAddPath(ctx, trackPath.CGPath)
            CGContextFillPath(ctx)
        }
        
        
        // Draw ticks
        CGContextSetFillColorWithColor(ctx, stepTickColor.CGColor)
        
        for index in 0..<steps {
            
            let x = Double(trackOffset) + (Double(index) * stepWidth) - Double(stepTickWidth / 2)
            let y = Double(bounds.midY) - (stepTickHeight / 2)
            
            // Create rounded/squared tick bezier
            let stepPath: UIBezierPath
            if customTrack && stepTickRounded {
                stepPath = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: Double(stepTickWidth), height: stepTickHeight), cornerRadius: 5)
            } else {
                stepPath = UIBezierPath(rect: CGRect(x: x, y: y, width: Double(stepTickWidth), height: stepTickHeight))
            }
            
            CGContextAddPath(ctx, stepPath.CGPath)
            CGContextFillPath(ctx)
        }
        
        CGContextRestoreGState(ctx)
    }
}


// MARK: - Touch Handling
extension StepSlider {
    
    override public func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let location = touch.locationInView(self)
        originalValue = Int(value)
        
        if thumbRect.contains(location) {
            dragging = true
        } else {
            dragging = false
        }
        
        previousLocation = location
        
        return dragging
    }
    
    override public func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let location = touch.locationInView(self)
        
        let deltaLocation = Double(location.x) - Double(previousLocation.x)
        let deltaValue = Int(round(fabs(deltaLocation) / stepWidth))
        
        func clipValue(value: Int) -> Int {
            return min(max(value, Int(minimumValue)), Int(maximumValue))
        }
        
        if deltaLocation < 0 {
            value = Float(clipValue(originalValue - deltaValue))  // Slide left
        } else {
            value = Float(clipValue(originalValue + deltaValue))  // Slide right
        }
        
        // Update UI without animation
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        setNeedsLayout()
        CATransaction.commit()
        
        return true
    }
    
    override public func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        previousLocation = CGPointZero
        originalValue = 0
        dragging = false
        
        if self.continuous == false {
            self.sendActionsForControlEvents(.ValueChanged)
        }
    }
}

// MARK: - Helpers
extension StepSlider {
    func setupView() {
        minValue = 0
        maxValue = 4
    }
}


// MARK: - IB
extension StepSlider {
    override public func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
        drawTrack()
        
        value = 1
    }
}