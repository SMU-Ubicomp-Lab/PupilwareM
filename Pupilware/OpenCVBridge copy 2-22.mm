//
//  OpenCVBridge.m
//  LookinLive
//
//  Created by Eric Larson on 8/27/15.
//  Copyright (c) 2015 Eric Larson. All rights reserved.
//

#import "OpenCVBridge.h"

#import "AVFoundation/AVFoundation.h"
#import <opencv2/opencv.hpp>
#import <opencv2/highgui/cap_ios.h>
#import "PWPupilProcessor.h"


using namespace cv;

@implementation OpenCVBridge


// http://stackoverflow.com/questions/30867351/best-way-to-create-a-mat-from-a-ciimage

// http://stackoverflow.com/questions/10254141/how-to-convert-from-cvmat-to-uiimage-in-objective-c


+ (CIImage*)OpenCVTransferAndReturnFaces:(CIFaceFeature *)faceFeature usingImage:(CIImage*)ciFrameImage andContext:(CIContext*)context andProcessor:(PWPupilProcessor *)processor andLeftEye:(CGPoint)leftEyePoint andRightEye:(CGPoint)rightEyePoint andIsFinished:(BOOL) isFinished  {
    
    // BEGIN == The following code is for transformation.
//            CGRect faceRect = CGRectApplyAffineTransform(faceFeature.bounds, transform);
//            
//            const CGPoint leftEyePos = CGPointApplyAffineTransform(faceFeature.leftEyePosition, transform);
//            rightEyePoint  = CGPointApplyAffineTransform(faceFeature.rightEyePosition, transform);
//        
//            CGPoint tmpLeftEyePos = leftEyePos;
//            CGPoint originalLeftEyePos = leftEyePoint;
//            leftEyePoint = leftEyePos;
//        //

    // END == Transformation Code
    
    // UIGraphicsBeginImageContext(faceFeature.bounds.size); // NOT SURE WHAT THIS WILL POSSIBLY DO

    
    //get face bounds and copy over smaller face image as CIIMage
    CGRect faceRect = faceFeature.bounds;
    
    
    // LEFT EYE, create rectangle, image reference, and openCV Mat
    
    // Creating left eye rectangle.
    CGRect leftEyeRect;
    leftEyeRect.origin.x =  leftEyePoint.x - 40;
    leftEyeRect.origin.y = leftEyePoint.y - 40;
    leftEyeRect.size.width = 80;
    leftEyeRect.size.height = 80;
    
    // Left eye image reference
    
    CGImageRef leftEyeImageCG = [context createCGImage:ciFrameImage fromRect:leftEyeRect];
    
    // Left Eye OpenCV mat
    cv::Mat leftEyeGrayMat;
    CGColorSpaceRef leftEyeColorSpace = CGImageGetColorSpace(leftEyeImageCG);
    CGFloat leftEyeCols = leftEyeRect.size.width;
    CGFloat leftEyeRows = leftEyeRect.size.height;
    cv::Mat leftEyeMat(leftEyeRows, leftEyeCols, CV_8UC4); // 8 bits per component, 4 channel
    

    // Image referecne for the left eye
    
    CGContextRef leftEyeContextRef = CGBitmapContextCreate(leftEyeMat.data,                 // Pointer to backing data
                                                    leftEyeCols,                      // Width of bitmap
                                                    leftEyeRows,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    leftEyeMat.step[0],              // Bytes per row
                                                    leftEyeColorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    // do the copy
//    CGContextDrawImage(leftEyeContextRef, CGRectMake(leftEyeRect.origin.x, leftEyeRect.origin.y, leftEyeCols, leftEyeRows), leftEyeImageCG);
    
       CGContextDrawImage(leftEyeContextRef, CGRectMake(0, 0, leftEyeCols, leftEyeRows), leftEyeImageCG);

    
    // release intermediary buffer objects
    CGContextRelease(leftEyeContextRef);
    CGImageRelease(leftEyeImageCG);
    
    // End Image reference for the left eye
    
    
    // RIGHT EYE
    // Creating right eye rectangle.
    CGRect rightEyeRect;
    rightEyeRect.origin.x = rightEyePoint.x-40;
    rightEyeRect.origin.y = rightEyePoint.y-40;
    rightEyeRect.size.width = 80;
    rightEyeRect.size.height = 80;
    

    // Right eye image reference
    CGImageRef rightEyeImageCG = [context createCGImage:ciFrameImage fromRect:rightEyeRect];
    
    // Right Eye OpenCV mat
    cv::Mat rightEyeGrayMat;
    CGColorSpaceRef rightEyeColorSpace = CGImageGetColorSpace(rightEyeImageCG);
    CGFloat rightEyeCols = rightEyeRect.size.width;
    CGFloat rightEyeRows = rightEyeRect.size.height;
    cv::Mat rightEyeMat(rightEyeRows, rightEyeCols, CV_8UC4); // 8 bits per component, 4 channels

    // Image referecne for the right eye
    
    CGContextRef rightEyeContextRef = CGBitmapContextCreate(rightEyeMat.data,                 // Pointer to backing data
                                                           rightEyeCols,                      // Width of bitmap
                                                           rightEyeRows,                     // Height of bitmap
                                                           8,                          // Bits per component
                                                           rightEyeMat.step[0],              // Bytes per row
                                                           rightEyeColorSpace,                 // Colorspace
                                                           kCGImageAlphaNoneSkipLast |
                                                           kCGBitmapByteOrderDefault); // Bitmap info flags
    // do the copy
    CGContextDrawImage(rightEyeContextRef, CGRectMake(0, 0, rightEyeCols, rightEyeRows), rightEyeImageCG);
    
//    CGContextDrawImage(rightEyeContextRef, CGRectMake(rightEyeRect.origin.x, rightEyeRect.origin.y, rightEyeCols, rightEyeRows), rightEyeImageCG);

    
    // release intermediary buffer objects
    CGContextRelease(rightEyeContextRef);
    CGImageRelease(rightEyeImageCG);
    
    // End Image reference for the right eye
    
     // Face image reference
    CGImageRef faceImageCG = [context createCGImage:ciFrameImage fromRect:faceRect];
    
    // setup the OPenCV mat -- Face Image --  fro copying into
    cv::Mat frame_gray;
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(faceImageCG);
    CGFloat cols = faceRect.size.width;
    CGFloat rows = faceRect.size.height;
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    
    // setup the copy buffer (to copy from the GPU)
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    // do the copy
    
   // CGContextMoveToPoint(contextRef, faceRect.origin.x , faceRect.origin.y);

    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), faceImageCG);
    
    
    // release intermediary buffer objects
    CGContextRelease(contextRef);
    CGImageRelease(faceImageCG);
    
    //insert processing here===================
    cvtColor( leftEyeMat, leftEyeGrayMat, CV_BGR2GRAY );

    cvtColor( rightEyeMat, rightEyeGrayMat, CV_BGR2GRAY );

    cvtColor( cvMat, frame_gray, CV_BGR2GRAY );
    
    
    cv::Mat cvMatToShowOnScreen;
    
    processor->faceAndEyeFeatureExtraction(frame_gray, leftEyeGrayMat, rightEyeGrayMat, leftEyeMat, rightEyeMat, cv::Rect(leftEyeRect.origin.x, leftEyeRect.origin.y, leftEyeCols, leftEyeRows), cv::Rect(rightEyeRect.origin.x, rightEyeRect.origin.y, rightEyeCols, rightEyeRows), isFinished, cvMatToShowOnScreen);
    
 //
    //end processing==========================

    
    // convert back
    // setup NS byte buffer using the data from the cvMat to show
    NSData *data = [NSData dataWithBytes:cvMatToShowOnScreen.data length:cvMatToShowOnScreen.elemSize() * cvMatToShowOnScreen.total()];
    
    
    if (cvMatToShowOnScreen.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    // setup buffering object
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // setup the copy to go from CPU to GPU
    CGImageRef imageRef = CGImageCreate(cvMatToShowOnScreen.cols,                                     // Width
                                        cvMatToShowOnScreen.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * cvMatToShowOnScreen.elemSize(),                           // Bits per pixel
                                        cvMatToShowOnScreen.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    // do the copy inside of the object instantiation for retImage
    CIImage* retImage = [[CIImage alloc]initWithCGImage:imageRef];
    
    
    // clean up
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return retImage;
    
}

// testing of the passing of params to swift
+(void)testFaceFeature:(CIFaceFeature *)faceFeature{
    
}

+(void)testImage:(CIImage*)ciFrameImage{
    
}

+(void)testContext:(CIContext*)context{
    
}

@end
