//
//  PWProcessor.h
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 8/2/16.
//  Copyright © 2016 Chatchai Mark Wangwiwattana. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/opencv.hpp>

@interface PWProcessor : NSObject

-(void) addFrame:(const cv::Mat&) frame withFrameNumber:(unsigned long) frameNumber;
-(const cv::Mat&)getDebugFrame;
-(void) start;
-(void) stop;
-(BOOL) isStarted;
-(BOOL) hasFace;

@end

