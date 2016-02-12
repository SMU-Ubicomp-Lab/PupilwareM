//
//  SettingsViewController.h
//  CogSense
//
//  Created by Sohail Rafiqi on 2/5/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PWViewController.h"

@interface SettingsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *s_eyeDistance;
@property (weak, nonatomic) IBOutlet UITextField *s_windowSize;

@property (weak, nonatomic) IBOutlet UITextField *s_mbWindowSize;
@property (weak, nonatomic) IBOutlet UITextField *s_baselineStart;
@property (weak, nonatomic) IBOutlet UITextField *s_baselineEnd;
@property (weak, nonatomic) IBOutlet UITextField *s_threshold;
@property (weak, nonatomic) IBOutlet UITextField *s_markCost;
@property (weak, nonatomic) IBOutlet UITextField *s_baseline;
@property (weak, nonatomic) IBOutlet UITextField *s_cogHightSize;

- (IBAction)save:(id)sender;

@end
