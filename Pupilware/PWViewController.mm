//
//  PWViewController.m
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/24/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

#import "PWViewController.h"

#import "PupilwareCore/preHeader.hpp"
#import "PWProcessor.h"
#import "PWIOSVideoReader.h"
#import "Pupilware-Swift.h"

#import "PupilwareCore/PWVideoWriter.hpp"
#import "Libraries/ObjCAdapter.h"
//#import "constants.h"

@class DataModel;

/*---------------------------------------------------------------
 Pupilware Core Header
 ---------------------------------------------------------------*/
#import "PupilwareCore/IOS/IOSFaceRecognizer.h"

/*---------------------------------------------------------------
 Objective C Header
 ---------------------------------------------------------------*/

@interface PWViewController ()

@property (strong, nonatomic) PWIOSVideoReader *videoManager;       /* Manage iOS Video input      */
@property (strong, nonatomic) IOSFaceRecognizer *faceRecognizer;    /* recognize face from ICImage */
@property (strong, nonatomic) DataModel *model;                      /* Connect with Swift UI       */
@property (strong, nonatomic) PWProcessor *processor;

@property NSUInteger currentFrameNumber;

- (IBAction)startBtnClicked:(id)sender;

@end


@implementation PWViewController
{
    cw::CWClock mainClock;
    pw::PWVideoWriter videoWriter;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////    Instantiation    //////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////

-(PWIOSVideoReader*)videoManager{
    if(!_videoManager){
        _videoManager = [[PWIOSVideoReader alloc] init];
        
        [self initVideoManager];
        
    }
    return _videoManager;
    
}

-(DataModel*)model{
    if(!_model){
        _model = [DataModel sharedInstance];
    }
    return _model;
}

-(PWProcessor*)processor{
    if(!_processor){
        _processor = [[PWProcessor alloc] init];
    }
    
    return _processor;
}


/////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////    UI View Events Handler    /////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self startVideoManager];
    
    [self.processor start];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [self stopVideoManager];
    [self.processor stop];
    videoWriter.close();
    
    [super viewWillDisappear:animated];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (IBAction)startBtnClicked:(id)sender {
    
    [self togglePupilware];
    
    if([self.processor isStarted])
    {
        [sender setTitle:@"Stop" forState: UIControlStateNormal];
    }
    else
    {
        [sender setTitle:@"Start" forState:UIControlStateNormal];
    }
}

//- (IBAction)onSaveClicked:(id)sender {
//    NSString* filePath = [ObjCAdapter getOutputFilePath:@"pupil.csv"];
//    
//    auto pupilStorage = pupilwareController->getRawPupilSignal();
//    pw::PWCSVExporter::toCSV(pupilStorage, [filePath UTF8String]);
//}


/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////    Objective C Implementation     /////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////



-(void)startVideoManager
{
    if(![self.videoManager isRunning])
    {
        [self.videoManager start];
    }
}


-(void)stopVideoManager
{
    if([self.videoManager isRunning])
    {
        [self.videoManager stop];
    }
}


-(void) togglePupilware{
    
    if([self.processor isStarted])
    {
        [self.processor stop];
        videoWriter.close();
    }
    else
    {
        [self.processor start];
        [self initVideoWriter];
    }

}

-(void)initVideoWriter
{
    
    //    NSString* fileName = self.model.getFaceFileName;
    NSString* fileName = @"face.mp4";
    
    NSString* videoPath = [ObjCAdapter getOutputFilePath: fileName];
    
    cv::Size frameSize (720,1280);
    if(!videoWriter.open([videoPath UTF8String], 15, frameSize))
    {
        NSLog(@"Video Writer is not opened correctedly.");
    }
}



- (void)initVideoManager
{
    
    /* Process from a video file, uncomment this block*/
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"v513.mp4"];
    [self.videoManager open:filePath];
    /*----------------------------------------------------------------------------------------*/
    
    
    // remove the view's background color
    self.view.backgroundColor = nil;
    
    
    __block typeof(self) blockSelf = self;
    
    [self.videoManager setProcessBlock:^(const cv::Mat& cvFrame){
        
        if (![blockSelf.processor isStarted]) {
            return cvFrame;
        }
        
        cv::Mat returnFrame = cvFrame;
        
        blockSelf->videoWriter << cvFrame;

        [blockSelf updateUI: [blockSelf.processor hasFace]];
        

        /* Put data to shared memory */
        {
            [blockSelf.processor addFrame:cvFrame
                          withFrameNumber:blockSelf.currentFrameNumber ];
            
//            NSLog(@">> add %lu", (unsigned long)blockSelf.currentFrameNumber);
            
            returnFrame = [blockSelf.processor getDebugFrame];

        }

        /* Move to next frame */
        [blockSelf advanceFrame];
        
        
//        NSLog(@"spf %f", blockSelf->mainClock.getTime());
//        blockSelf->mainClock.reset();
        
        return returnFrame;
        
        
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
     
    }];

}

-(void) updateUI:(bool) hasFace
{
    if(hasFace)
    {
        self.model.faceInView = true;
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self.model.bridgeDelegate faceInView];
                       });
    }
    else{
        self.model.faceInView = false;
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self.model.bridgeDelegate faceNotInView];
                       });
    }
}


-(void) advanceFrame{
    self.currentFrameNumber += 1;
    
    if ([self.model.bridgeDelegate isTestingFinished]) {
        [self.processor stop];
        [self.videoManager stop];
        videoWriter.close();
    }
}

@end
