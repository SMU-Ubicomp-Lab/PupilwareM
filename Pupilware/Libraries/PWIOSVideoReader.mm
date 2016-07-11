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
        _videoManager.preset = AVCaptureSessionPresetHigh;
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

        __weak typeof(self) weakSelf = self;
        
        [self.videoManager setProcessBlock:^(CIImage *cameraImage){

            if (weakSelf.isOpened) {
                cv::Mat frame;
                
                capture >> frame;
                
                CIImage* returnImage = cameraImage;
                
                if(!frame.empty()){
                    cv::Mat debugFrame;
                    debugFrame = weakSelf.processBlock(frame);
                    /* Rotate it back. */
                    [ObjCAdapter Rotate90:debugFrame withFlag:2];
                    returnImage = [ObjCAdapter Mat2CGImage:debugFrame
                                                withContext:weakSelf.videoManager.ciContext];
                }
                
                
                return returnImage;
            }
            else{
                return cameraImage;
            }
            
        }];
    }
    else{
        
         __weak typeof(self) weakSelf = self;
        _processBlock = [pBlock copy];
        
        [self.videoManager setProcessBlock:^(CIImage *cameraImage){
            
            /* The source image is in sideway (<-), so It need to be rotated back up. */
            CGAffineTransform transform = CGAffineTransformMakeRotation(-M_PI_2);
            transform = CGAffineTransformTranslate(transform,-cameraImage.extent.size.width,0);
            cameraImage = [cameraImage imageByApplyingTransform:transform];
            
            
            cv::Mat cvFrame = [ObjCAdapter IGImage2Mat:cameraImage
                                           withContext:weakSelf.videoManager.ciContext];
            
            /* process the frame somewhere else.*/
            cv::Mat returnFrame = weakSelf.processBlock(cvFrame);
            
            /* Rotate it back. */
            [ObjCAdapter Rotate90:returnFrame withFlag:2];
            
            CIImage* returnImage = [ObjCAdapter Mat2CGImage:returnFrame
                                                withContext:weakSelf.videoManager.ciContext];
            
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
