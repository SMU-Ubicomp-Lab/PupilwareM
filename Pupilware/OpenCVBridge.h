//
//  OpenCVBridge.h
//  LookinLive
//
//  Created by Eric Larson on 8/27/15.
//  Copyright (c) 2015 Eric Larson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import "PWPupilProcessor.hpp"
#import "PWViewController.h"

using namespace pw;

@interface OpenCVBridge : NSObject

+ (CIImage*)OpenCVTransferAndReturnFaces:(CIFaceFeature *)faceFeature usingImage:(CIImage*)ciFrameImage andContext:(CIContext*)context andProcessor: (PWPupilProcessor *)processor andLeftEye: (CGPoint) leftEyePoint andRightEye: (CGPoint) rightEyePoint andIsFinished: (BOOL) isFinished;

+(void)testFaceFeature:(CIFaceFeature *)faceFeature;

+(void)testImage:(CIImage*)ciFrameImage;

+(void)testContext:(CIContext*)context;



@end
