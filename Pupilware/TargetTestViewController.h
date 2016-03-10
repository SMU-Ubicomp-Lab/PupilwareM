//
//  TargetTestViewController.h
//  CogSense
//
//  Created by Sohail Rafiqi on 11/5/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>


@interface TargetTestViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *iterationText;
@property (weak, nonatomic) IBOutlet UILabel *iterationLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@end
