//
//  commandControl.h
//  CogSense
//
//  Created by Sohail Rafiqi on 1/31/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PWViewController.h"
//#import "LookingLiveViewController.h"

@interface commandControl : UIViewController <UIPickerViewDataSource,UIPickerViewDelegate,UITextFieldDelegate>
- (IBAction)exitToHere:(UIStoryboardSegue *)sender;

@property (weak, nonatomic) IBOutlet UILabel *experiment;
@property (weak, nonatomic) IBOutlet UIPickerView *expPicker;
@property (weak, nonatomic) IBOutlet UILabel *iteration;
@property (weak, nonatomic) IBOutlet UITextField *idText;

// @property (weak, nonatomic) IBOutlet UISwitch *liveCaptureToggle;


@end
