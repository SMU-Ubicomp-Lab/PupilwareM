//
//  ObjCAdapter.h
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/26/16.
//  Copyright © 2016 SMU Ubicomp Lab All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObjCAdapter : NSObject

/*
 * Rotate Mat 90 degree
 */
+(void)Rotate90:(cv::Mat&)opencvMat withFlag:(int)rotflag;


/*
 * CIImage to OpenCV Mat
 * It copy memory, so use with certion.
 */
+(cv::Mat)CIImage2Mat:(CIImage*)ciFrameImage withContext:(CIContext*)context;


/*
 * OpenCV to CIImage
 * It copies memory
 */
+(CIImage*) Mat2CIImage:(cv::Mat)opencvMat withContext:(CIContext*)context;


/*
 * Standard Vector to NSArray
 * It copies memory
 */
+(NSArray*) vector2NSArray:( const std::vector<float>& )v;


/*
 * Convert CGRect to OpenCV Rect
 */
+(cv::Rect) CGRect2CVRect:(CGRect) cgRect;


/*
 * Convert CGPoint to OpenCV Point
 */
+(cv::Point) CGPoint2CVPoint:(CGPoint) cgPoint;


/*
 * Get IOS directory path.
 * If file is already exited, it deletes the file before return the path.
 * It is quite dangerous, be careful.
 */
+(NSString*)getOutputFilePath:(NSString*) outputFileName;


@end
