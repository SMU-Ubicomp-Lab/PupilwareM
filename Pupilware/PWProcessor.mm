//
//  PWProcessor.m
//  Pupilware
//
//  This class connect to C++ Pupilware Core.
//  It also provides higher level interface for users.
//
//  Created by Chatchai Wangwiwattana on 8/2/16.
//  Copyright © 2016 Chatchai Mark Wangwiwattana. All rights reserved.
//


#import "PWProcessor.h"

#import "PupilwareCore/preHeader.hpp"
#import "PupilwareCore/PupilwareController.hpp"
#import "PupilwareCore/Algorithm/IPupilAlgorithm.hpp"
#import "PupilwareCore/Algorithm/MDStarbustNeo.hpp"
#import "PupilwareCore/Algorithm/MaximumCircleFit.hpp"
#import "PupilwareCore/Algorithm/BlinkDetection.hpp"
#import "PupilwareCore/ImageProcessing/SimpleImageSegmenter.hpp"


#import "PupilwareCore/PWCSVExporter.hpp"

#import "Libraries/ObjCAdapter.h"

@interface PWProcessor()

@property (atomic) BOOL b_startedThread;
@property (strong, nonatomic) dispatch_queue_t queue;
@end



@implementation PWProcessor
{
    std::shared_ptr<pw::PupilwareController> pupilwareController;
    std::shared_ptr<pw::MDStarbustNeo> pwAlgo;
    
    pw::PWCSVExporter csvExporter;
    
    
    //this block is sharing memory
    cv::Mat currentFrame;
    cv::Mat debugFrame;
    unsigned long currentFrameNumber;
    //----------------------
    
    int previousFrameNumber;
}

-(id)init{
    
    if( [super init] ){
        
        self.outputFileName = @"face.csv";
        [self initPupilwareCtrl];
        
    }
    
    return self;
}

-(void) setParameter:(PWParameter*)params{
    
    if(params == nil ){
        NSLog(@"Parameter is nil. Reject the request.");
        return;
    }
    
//    pwAlgo->setSigma([params.sigma floatValue]);
//    pwAlgo->setPrior([params.prior floatValue]);
//    pwAlgo->setThreshold([params.threshold floatValue]);
//    pwAlgo->setRayNumber([params.sbRayNumber intValue]);
//    pwAlgo->setDegreeOffset([params.degreeOffset intValue]);
    
}


-(void) addFrame:(const cv::Mat&) frame withFrameNumber:(unsigned long) frameNumber{
    
    @synchronized (self) {
        currentFrame = frame.clone();
        currentFrameNumber = frameNumber;
    }

}


-(void) start{
    if(!pupilwareController->hasStarted())
    {
        NSLog(@"[Info] Pupilware is starting...");
        
        pupilwareController->start();
        currentFrameNumber = 0;
        
        [self initCSVExporter];
        
        [self startProcessThread];
    }
}


-(void) stop{
    if(pupilwareController->hasStarted())
    {
        [self stopProcessThread];
        
        // TODO: change the sleep function to waiting until the thread is returned.
        NSLog(@"[Info] Pupilware Start cleaning up.");
        sleep(1);
        
        pupilwareController->stop();
        pupilwareController->clearBuffer();
        csvExporter.close();
        
        NSLog(@"[Info] Pupilware is fully closed.");
    }
}

-(void)startProcessThread{
    
    self.b_startedThread = YES;
    
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(self.queue, ^{
        
        NSLog(@"[Info] Pupilware Thread is started.");
        
        while(self.b_startedThread){
            
            int currentFrameN = 0;
            cv::Mat frame;
            
            /* Copy data from shared memory */
            @synchronized (self) {
                
                /* Check if there is new data. */
                if( previousFrameNumber == self->currentFrameNumber ) continue;
                if( currentFrame.empty() ) continue;
                
                /* copy data to local variables*/
                currentFrameN = (int)self->currentFrameNumber;
                frame = currentFrame.clone();
                
                /* store last frame debug image */
                /* just in case someone else what the data */
                cv::Mat debugImg = [self _getDebugImage];
                
                if(debugImg.empty()){
                    debugImg = frame;
                }
                self->debugFrame = debugImg.clone();
                
            }
            
            /* Check again if data is successfully copied */
            if (frame.empty()) {
                continue;
            }
            
//            cw::CWClock c;
            
            /* Process the rest of the work (e.g. pupil segmentation..) */
            self->pupilwareController->processFrame(frame, currentFrameN );
            self->csvExporter << self->pupilwareController->getFaceMeta();
            
            
//            NSLog(@"previousFrameNumber %d, currentFrameNumber %d", previousFrameNumber, currentFrameN);
            previousFrameNumber = currentFrameN;
            
//            sleep(0.1);
//            NSLog(@"spfP %f", c.stop());
            
        }
        
        NSLog(@"[Info] Pupilware Thread is returned.");
        
    });

}

-(void)stopProcessThread{
    self.b_startedThread = NO;
}


-(BOOL) isStarted{
    
    return pupilwareController->hasStarted();
}


-(BOOL) hasFace{
    
    return pupilwareController->getFaceMeta().hasFace();
}


-(void)initCSVExporter
{
    
    NSString* filePath = self.outputFileName;
    csvExporter.open([filePath UTF8String]);
}


-(void)initPupilwareCtrl
{
    
    self->currentFrameNumber = 0;
    
    pupilwareController = pw::PupilwareController::Create();
    pwAlgo = std::make_shared<pw::MDStarbustNeo>("MDStarburstNeo");

    pupilwareController->setPupilSegmentationAlgorihtm( pwAlgo );
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
    const char *filePath = [path cStringUsingEncoding:NSUTF8StringEncoding];
    pupilwareController->setFaceSegmentationAlgoirhtm(std::make_shared<pw::SimpleImageSegmenter>(filePath));
  
    
}

-(cv::Mat)getDebugFrame{
    
    cv::Mat temp;
    
    @synchronized (self) {
        temp = self->debugFrame.clone();
    }
    
    return temp;
    
}



-(cv::Mat)_getDebugImage
{
    cv::Mat debugImg = pupilwareController->getDebugImage();
    
    /* I have to put the debug of eye image in subclass,
     * because the debug eye image become empty if I put it in the algorithm interface.
     * If someone help me clean this thing up would be appreciated.
     */
    if(!debugImg.empty()){
        
        cv::Mat debugEyeImg = pwAlgo->getDebugImage();
        
        /* Combind 2 debug images into one */
        if(!debugEyeImg.empty()){
            cv::resize(debugEyeImg, debugEyeImg, cv::Size(debugImg.cols, debugEyeImg.rows*2));
            cv::cvtColor(debugEyeImg, debugEyeImg, CV_BGR2RGBA);
            debugEyeImg.copyTo(debugImg(cv::Rect(0, 0, debugEyeImg.cols, debugEyeImg.rows)));
        }
        
    }
    
    return debugImg;
}



//TODO: Enable This block in release built.
/********************************************
 try{
 // Whatever code in the block is, put it in here.!
 }
 catch(AssertionFailureException e){
 
 //Catch if anything wrong during processing.
 
 std::cerr<<"[ERROR!!] Assertion does not meet. Serious error detected. " << std::endl;
 e.LogError();
 
 //TODO: Manage execption, make sure data is safe and saved.
 // - save files
 // - destroy damage memory
 // - Show UI Error message
 // - write log files
 
 return cameraImage;
 
 }
 */



@end
