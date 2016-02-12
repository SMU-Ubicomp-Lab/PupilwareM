//
//  DisplayDataViewController.h
//  CogSense
//
//  Created by Sohail Rafiqi on 2/4/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BEMSimpleLineGraphView.h"
#import "PWParameter.h"

@interface CalibrationResultViewController : UITableViewController <BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate>

@property (weak, nonatomic) IBOutlet BEMSimpleLineGraphView *myGraph;
@property (weak, nonatomic) IBOutlet BEMSimpleLineGraphView *myGraph2;
@property (weak, nonatomic) IBOutlet BEMSimpleLineGraphView *myGraph3;
@property (weak, nonatomic) IBOutlet BEMSimpleLineGraphView *myGraph4;
@property (weak, nonatomic) IBOutlet BEMSimpleLineGraphView *myGraph5;

@property (weak, nonatomic) IBOutlet UILabel *sdLabel1;
@property (weak, nonatomic) IBOutlet UILabel *sdLabel2;
@property (weak, nonatomic) IBOutlet UILabel *sdLabel3;
@property (weak, nonatomic) IBOutlet UILabel *sdLabel4;
@property (weak, nonatomic) IBOutlet UILabel *sdLabel5;


@property (strong,nonatomic) NSArray* dataPoints;
@property (strong,nonatomic) NSArray* dataPoints2;
@property (strong,nonatomic) NSArray* dataPoints3;
@property (strong,nonatomic) NSArray* dataPoints4;
@property (strong,nonatomic) NSArray* dataPoints5;

@property (strong,nonatomic) NSArray* stdValues;
@property (strong,nonatomic) NSArray* baselineValues;

@property (strong,nonatomic) NSMutableArray* parameters;

@property (nonatomic) BOOL isCalibMax;
@property (strong, nonatomic) NSNumber* thePeak;
@end
