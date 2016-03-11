//
//  TestCalibrateViewController.h
//  CogSense
//
//  Created by Sohail Rafiqi on 3/10/16.
//  Copyright © 2016 SMU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "commandControl.h"
#import "MyCvVideoCamera.h"
#import "PWParameter.h"


@interface TestCalibrateViewController : UIViewController


@property (weak, nonatomic) NSString *participant;
@property (weak, nonatomic) NSString *experiment;
@property (weak, nonatomic) NSString *iteration;
@property BOOL isRunnningFromVideoMode;
@property BOOL baseline;
@property BOOL isCalibCogMax;
@property (nonatomic) NSInteger numberOfIteration;


@end
