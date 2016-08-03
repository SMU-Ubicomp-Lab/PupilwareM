//
//  PWIOSVideoReader.m
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 7/11/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

#import "PWIOSVideoReader.h"

#import "VideoAnalgesic.h"
#import "ObjCAdapter.h"
#import "../PupilwareCore/Core/profiler/CWClock.hpp"

@interface PWIOSVideoReader()

@property (strong, nonatomic) VideoAnalgesic *videoManager;         /* Manage iOS Video input */
@property BOOL b_opened;                                            /* Is the file successful loaded*/
@property BOOL b_readFromFile;                                      /* Is it in offline mode */

@end


@implementation PWIOSVideoReader
{
    cv::VideoCapture    capture;
}

-(VideoAnalgesic*)videoManager{
    if(!_videoManager){
        _videoManager = [VideoAnalgesic captureManager];
        _videoManager.preset = AVCaptureSessionPreset1280x720;
        [_videoManager setCameraPosition:AVCaptureDevicePositionFront];
        
    }
    return _videoManager;
    
}

-(id)init{
    
    if( [super init]){
        self.b_opened = NO;
        self.b_readFromFile = NO;
        self.ciContext = self.videoManager.ciContext;
    }
    
    return self;
}


-(BOOL)open:(NSString*)filename{
    
    if(filename == nil){
        self.b_opened = YES;
    }
    else{
        
        bool result = capture.open([filename UTF8String]);
        
        self.b_opened = result;
        self.b_readFromFile = YES;
    }
    
    return self.b_opened;
}


-(BOOL)isOpened{
    return self.b_opened;
}


-(void)setProcessBlock:(CVProcessBlock) pBlock{
    
    if(self.b_readFromFile){
        _processBlock = [pBlock copy];

        __block typeof(self) blockSelf = self;
        
        [self.videoManager setProcessBlock:^(CIImage *cameraImage){

            if (blockSelf.isOpened) {
                cv::Mat frame;
                
                blockSelf->capture >> frame;
                
                CIImage* returnImage = cameraImage;
                
                if(!frame.empty()){
                    cw::CWClock clock;
                    
                    cv::Mat debugFrame;
                    debugFrame = blockSelf.processBlock(frame);

                    
                    /* Draw Time*/
                    auto dtMS = clock.stop();
                    NSString *fps = [NSString stringWithFormat:@"SPF %f", dtMS];
                    
//                    NSLog(fps);
                    
                    cv::putText(debugFrame,[fps UTF8String], cv::Point(10,80), cv::FONT_HERSHEY_SIMPLEX, 1, cv::Scalar(255,255,255) );
                    
                    
                    /* Rotate it back. */
                    [ObjCAdapter Rotate90:debugFrame withFlag:2];
                    returnImage = [ObjCAdapter Mat2CIImage:debugFrame
                                               withContext:blockSelf.videoManager.ciContext];
                }
                else{
                    blockSelf.processBlock(cv::Mat());
                }
                
                
                return returnImage;
            }
            else{
                return cameraImage;
            }
            
        }];
    }
    else{
        
         __block typeof(self) blockSelf = self;
        _processBlock = [pBlock copy];
        
        [self.videoManager setProcessBlock:^(CIImage *cameraImage){
            
            /* The source image is in sideway (<-), so It need to be rotated back up. */
            CGAffineTransform transform = CGAffineTransformMakeRotation(-M_PI_2);
            transform = CGAffineTransformTranslate(transform,-cameraImage.extent.size.width,0);
            cameraImage = [cameraImage imageByApplyingTransform:transform];
            
            
            cv::Mat cvFrame = [ObjCAdapter CIImage2Mat:cameraImage
                                           withContext:blockSelf.videoManager.ciContext];
            
            /* process the frame somewhere else.*/
            cv::Mat returnFrame = blockSelf.processBlock(cvFrame);
            
            /* Rotate it back. */
            [ObjCAdapter Rotate90:returnFrame withFlag:2];
            
            CIImage* returnImage = [ObjCAdapter Mat2CIImage:returnFrame
                                                withContext:blockSelf.videoManager.ciContext];
            
            return returnImage;
            
        }];

    }
    
}


-(BOOL)isRunning{
    
    return [self.videoManager isRunning];
}


-(void)start{

    [self.videoManager start];
}


-(void)stop{
    
    [self.videoManager stop];
}


-(void)dealloc{
    
    if(self.b_readFromFile){
        if(capture.isOpened())
        {
            capture.release();
        }
    }
    
   [self.videoManager stop];
}

@end
