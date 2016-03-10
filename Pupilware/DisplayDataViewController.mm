//
//  DisplayDataViewController.m
//  CogSense
//
//  Created by Sohail Rafiqi on 2/4/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#include <opencv2/opencv.hpp>
#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/core/core.hpp>

#import "DisplayDataViewController.h"
#import "constants.h"


@interface DisplayDataViewController ()



@end

@implementation DisplayDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.myGraph.dataSource = self;
    self.myGraph.delegate = self;

    
    self.myGraph.colorTop = [UIColor colorWithRed:31.0/255.0 green:187.0/255.0 blue:166.0/255.0 alpha:1.0];
    self.myGraph.colorBottom = [UIColor colorWithRed:31.0/255.0 green:187.0/255.0 blue:166.0/255.0 alpha:1.0];
    self.myGraph.colorLine = [UIColor whiteColor];
    self.myGraph.colorXaxisLabel = [UIColor whiteColor];
    self.myGraph.colorYaxisLabel = [UIColor whiteColor];
    //self.myGraph.widthLine = 3.0;
    self.myGraph.enableTouchReport = YES;
    self.myGraph.enablePopUpReport = YES;
    self.myGraph.enableBezierCurve = YES;
    self.myGraph.enableYAxisLabel = YES;
    self.myGraph.autoScaleYAxis = YES;
    self.myGraph.alwaysDisplayDots = NO;
    //self.myGraph.enableReferenceXAxisLines = YES;
    self.myGraph.enableReferenceYAxisLines = YES;
    self.myGraph.enableReferenceAxisFrame = YES;
    self.myGraph.animationGraphStyle = BEMLineAnimationDraw;
    
}

-(void)viewWillAppear:(BOOL)animated
{
    self.cogLevelBar.progress = [self.cogLevel floatValue];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Simple Line Graph Data Source
-(NSInteger)numberOfPointsInLineGraph:(BEMSimpleLineGraphView *)graph
{
    return [self.dataPoints count];

}

-(CGFloat)lineGraph:(BEMSimpleLineGraphView *)graph valueForPointAtIndex:(NSInteger)index
{
    // multiply by 10000 because the graph view does not support float label.
    return [[self.dataPoints objectAtIndex:index] floatValue]*10000;

}

#pragma mark - simple Line Graph Delegate
- (NSInteger)numberOfGapsBetweenLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph
{
    return 1;
}

- (NSString *)lineGraph:(BEMSimpleLineGraphView *)graph labelOnXAxisForIndex:(NSInteger)index
{
    NSString *label = [NSString stringWithFormat:@"%ld", (long)index];
    return [label stringByReplacingOccurrencesOfString:@" " withString:@"\n"];
}

-(NSInteger)numberOfYAxisLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph
{
    return 3;
}

@end
