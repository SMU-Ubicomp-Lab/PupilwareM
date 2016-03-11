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
#import "MyCvVideoCamera.h"



@interface PWViewController : UIViewController

@property (weak, nonatomic) NSString *participant;
@property (weak, nonatomic) NSString *experiment;
@property (weak, nonatomic) NSString *iteration;
@property BOOL  isRunnningFromVideoMode;
@property BOOL  baseline;
@property BOOL  game;

-(void) preparePupilProcessor;
-(CvVideoCamera *)videoCamera;


@end
