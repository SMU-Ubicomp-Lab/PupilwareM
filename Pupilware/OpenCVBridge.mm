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


void createOpenCVImageFromCoreImage(cv::Mat& outputImage, CIContext* context, CIImage* ciFrameImage, CGRect rect){
    CGImageRef imageCG = [context createCGImage:ciFrameImage fromRect:rect];
    
    // OpenCV mat
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageCG);
    CGFloat cols = rect.size.width;
    CGFloat rows = rect.size.height;
    cv::Mat cvImageMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channel
    
    
    // Image ref
    CGContextRef contextRef = CGBitmapContextCreate(cvImageMat.data,                 // Pointer to backing data
                                                           cols,                      // Width of bitmap
                                                           rows,                     // Height of bitmap
                                                           8,                          // Bits per component
                                                           cvImageMat.step[0],              // Bytes per row
                                                           colorSpace,                 // Colorspace
                                                           kCGImageAlphaNoneSkipLast |
                                                           kCGBitmapByteOrderDefault); // Bitmap info flags
    // do the copy
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), imageCG);
    
    
    // release intermediary buffer objects
    CGContextRelease(contextRef);
    CGImageRelease(imageCG);
    
    outputImage = cvImageMat.clone(); // deep copy of the image and return 
}


+ (CIImage*)OpenCVTransferAndReturnFaces:(CIFaceFeature *)faceFeature
                              usingImage:(CIImage*)ciFrameImage
                              andContext:(CIContext*)context
                            andProcessor:(PWPupilProcessor *)processor
                              andLeftEye:(CGPoint)leftEyePoint
                             andRightEye:(CGPoint)rightEyePoint
                           andIsFinished:(BOOL) isFinished  {
  
    //get face bounds and copy over smaller face image as CIIMage
    CGRect faceRect = faceFeature.bounds;
    
    const int eyeSize = 60;
    
    // LEFT EYE Rect
    CGRect leftEyeRect;
    leftEyeRect.origin.x =  leftEyePoint.x - 2*eyeSize/5;
    leftEyeRect.origin.y = leftEyePoint.y - 1*eyeSize/2;
    leftEyeRect.size.width = eyeSize;
    leftEyeRect.size.height = eyeSize;
    
    // RIGHT EYE rect
    CGRect rightEyeRect;
    rightEyeRect.origin.x = rightEyePoint.x-2*eyeSize/5;
    rightEyeRect.origin.y = rightEyePoint.y-1*eyeSize/2;
    rightEyeRect.size.width = eyeSize;
    rightEyeRect.size.height = eyeSize;
    
    
    // Convert over the different bounds to OpenCV image mats
    // This process does go onto the GPU and copies the data into RAM (might be a bottelneck)
    
    // Left Eye OpenCV mat
    cv::Mat leftEyeGrayMat;
    cv::Mat leftEyeMat; // 8 bits per component, 4 channel
    createOpenCVImageFromCoreImage(leftEyeMat, context, ciFrameImage, leftEyeRect);

    // Right Eye OpenCV mat
    cv::Mat rightEyeGrayMat;
    cv::Mat rightEyeMat;
    createOpenCVImageFromCoreImage(rightEyeMat, context, ciFrameImage, rightEyeRect);
    
    // Face in OpenCV
    cv::Mat faceGray;
    cv::Mat face;
    createOpenCVImageFromCoreImage(face, context, ciFrameImage, faceRect);
    
    //start processing========================
    cvtColor( leftEyeMat, leftEyeGrayMat, CV_BGR2GRAY );
    cvtColor( rightEyeMat, rightEyeGrayMat, CV_BGR2GRAY );
    cvtColor( face, faceGray, CV_BGR2GRAY );
    
    
    cv::Mat cvMatToShowOnScreen;
    
    CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
    transform = CGAffineTransformTranslate(transform,
                                           0, -ciFrameImage.extent.size.height);
    const CGRect cvFaceRect = CGRectApplyAffineTransform(faceRect, transform);
    const CGRect cvleftEyeRect = CGRectApplyAffineTransform(leftEyeRect, transform);
    const CGRect cvrightEyeRect = CGRectApplyAffineTransform(rightEyeRect, transform);
    
    processor->faceAndEyeFeatureExtraction(faceGray,
                                           leftEyeGrayMat,
                                           rightEyeGrayMat,
                                           leftEyeMat,
                                           rightEyeMat,
                                           cv::Rect(cvleftEyeRect.origin.x-cvFaceRect.origin.x,cvleftEyeRect.origin.y-cvFaceRect.origin.y, cvleftEyeRect.size.width, cvleftEyeRect.size.height ),
                                           cv::Rect(cvrightEyeRect.origin.x-cvFaceRect.origin.x,cvrightEyeRect.origin.y-cvFaceRect.origin.y, cvrightEyeRect.size.width, cvrightEyeRect.size.height),
                                           isFinished,
                                           cvMatToShowOnScreen);
    
 //
    //end processing==========================

    CGColorSpaceRef colorSpace;
    
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
