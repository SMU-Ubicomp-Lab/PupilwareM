//
//  VideoAnalgesic.h
//  FilterImage
//
//  Created by Eric Larson 
//  Copyright (c) 2013 Eric Larson. All rights reserved.
// Code base modified from CIImageFunHouse
//      Copyright © 2013 Apple Inc. All rights reserved.
//      WWDC 2013 License
//
//      NOTE: This Apple Software was supplied by Apple as part of a WWDC 2013
//      Session. Please refer to the applicable WWDC 2013 Session for further
//      information.
//
// This code has been heavily modified, per the Apple license agreement for reuse


#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>


typedef CIImage*(^ProcessBlock)(CIImage *);

@interface VideoAnalgesic : NSObject{
    dispatch_queue_t captureSessionQueue;
    BOOL videoIsRunning;
}

@property (weak,nonatomic) UIView *window;
@property (strong,nonatomic) GLKView *videoPreviewView;
@property (strong,nonatomic)CIContext *ciContext;
@property (strong,nonatomic)EAGLContext *eaglContext;
@property (nonatomic) CGRect videoPreviewViewBounds;

@property (strong,nonatomic) AVCaptureDevice *videoDevice;
@property (strong,nonatomic) AVCaptureSession *captureSession;
@property (strong,nonatomic) NSString *preset;

@property (strong,nonatomic) ProcessBlock processBlock;
@property (strong,nonatomic) NSNumber *framesPerSecond;


+(id)captureManager;
+(NSNumber *)ciOrientationFromDeviceOrientation:(UIInterfaceOrientation)interfaceOrientation;
-(void)start;
-(void)stop;
-(BOOL)isRunning;
-(void)setCameraPosition:(AVCaptureDevicePosition)position;
- (void)shouldColorMatch:(BOOL)shouldColorMatch;

@end
