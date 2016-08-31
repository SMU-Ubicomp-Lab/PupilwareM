//
//  PWProcessor.h
//  Pupilware
//
//  This class connect to C++ Pupilware Core.
//  It also provides higher level interface for users.
//
//  Created by Chatchai Wangwiwattana on 8/2/16.
//  Copyright © 2016 Chatchai Mark Wangwiwattana. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/opencv.hpp>
#import "PupilwareCore/PWParameter.hpp"

@interface PWProcessor : NSObject

-(void) addFrame:(const cv::Mat&) frame withFrameNumber:(unsigned long) frameNumber;
-(cv::Mat)getDebugFrame;
-(void) start;
-(void) stop;
-(BOOL) isStarted;
-(BOOL) hasFace;
-(void) setParameter:(pw::PWParameter*)params;

@property(strong, nonatomic) NSString* outputFaceFileName;
@property(strong, nonatomic) NSString* outputPupilFileName;

@end

