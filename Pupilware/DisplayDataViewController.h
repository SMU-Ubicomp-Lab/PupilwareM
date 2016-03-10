//
//  DisplayDataViewController.h
//  CogSense
//
//  Created by Sohail Rafiqi on 2/4/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BEMSimpleLineGraphView.h"

@interface DisplayDataViewController : UIViewController <BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate>

@property (weak, nonatomic) IBOutlet BEMSimpleLineGraphView *myGraph;


@property (weak, nonatomic) IBOutlet UIProgressView *cogLevelBar;

@property (strong,nonatomic) NSArray* dataPoints;

@property (strong,nonatomic) NSNumber* cogLevel;

@end
