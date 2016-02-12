//
//  PWViewController.h
//  Pupilware
//
//  Created by Mark Wang on 4/1/14.
//  Copyright (c) 2014 SMU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "commandControl.h"
#import "VideoDisplayViewController.h"
#import "PWParameter.h"

@interface CalibrateViewController : UIViewController

@property (weak, nonatomic) NSString *participant;
@property (weak, nonatomic) NSString *experiment;
@property (weak, nonatomic) NSString *iteration;
@property BOOL isRunnningFromVideoMode;
@property BOOL baseline;
@property BOOL isCalibCogMax;
@property (nonatomic) NSInteger numberOfIteration;

-(void) preparePupilProcessor;


@end
