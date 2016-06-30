//
//  ObjCAdapter.h
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/26/16.
//  Copyright © 2016 SMU Ubicomp Lab All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjCAdapter : NSObject

+(void)Rotate90:(cv::Mat&)opencvMat withFlag:(int)rotflag;
+(cv::Mat)IGImage2Mat:(CIImage*)ciFrameImage withContext:(CIContext*)context;
+(CIImage*)Mat2CGImage:(cv::Mat)opencvMat withContext:(CIContext*)context;

+(cv::Rect) CGRect2CVRect:(CGRect) cgRect;
+(cv::Point) CGPoint2CVPoint:(CGPoint) cgPoint;

+(cv::Rect) CGRect2CVRectFlip:(CGRect) cgRect;
+(cv::Point) CGPoint2CVPointFlip:(CGPoint) cgPoint;


+(NSString*)getOutputFilePath:(NSString*) outputFileName;


@end
