//
//  VideoDisplayViewController.h
//  CogSense
//
//  Created by Sohail Rafiqi on 2/4/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PWViewController.h"
#import "CalibrateViewController.h"


@interface VideoDisplayViewController : UIViewController <UIPickerViewDataSource,UIPickerViewDelegate>
@property (weak, nonatomic) IBOutlet UIPickerView *part_IterPicker;
@property (weak, nonatomic) IBOutlet UILabel *participant_v;
@property (weak, nonatomic) IBOutlet UILabel *experiment_v;
@property (weak, nonatomic) IBOutlet UILabel *iteration_v;


@end
