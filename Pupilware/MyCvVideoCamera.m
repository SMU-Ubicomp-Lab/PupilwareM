//
//  MyCvVideoCamera.m
//  CogSense
//
//  Created by Mark Wang on 2/20/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//




#import "MyCvVideoCamera.h"

@implementation MyCvVideoCamera

@synthesize customPreviewLayer = _customPreviewLayer;

- (void)updateOrientation;
{
    // nop
}
- (void)layoutPreviewLayer;
{
    if (self.parentView != nil) {
        CALayer* layer = self.customPreviewLayer;
        CGRect bounds = self.customPreviewLayer.bounds;
        layer.position = CGPointMake(self.parentView.frame.size.width/2., self.parentView.frame.size.height/2.);
        layer.bounds = bounds;
    }
}
@end