//
//  MyCvVideoCamera.h
//  CogSense
//
//  Created by Mark Wang on 2/20/15.
//  Copyright (c) 2015 SMU. All rights reserved.
//

#ifndef CogSense_MyCvVideoCamera_h
#define CogSense_MyCvVideoCamera_h

#import <opencv2/videoio/cap_ios.h>

@interface MyCvVideoCamera : CvVideoCamera

- (void)updateOrientation;
- (void)layoutPreviewLayer;

@property (nonatomic, retain) CALayer *customPreviewLayer;

@end

@protocol CvVideoCameraDelegateMod <CvVideoCameraDelegate>
@end

#endif
