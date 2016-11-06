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
#import "constants.h"

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
    
//    if(self.preview)
//    {
//        [self.videoManager setPreviewView:self.preview];
//    }
    
    [self startSystem];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [self closeSystem];
    
    /* Video manage must stop last */
    [self.videoManager stop];
    
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


-(void) togglePupilware{
    
    if([self.processor isStarted])
    {
        [self closeSystem];
    }
    else
    {
        [self startSystem];
    }
    
}


/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////    Objective C Implementation     /////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////



-(void)startSystem
{
    if(![self.processor isStarted])
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        pw::PWParameter params;
        params.threshold=((float)[defaults floatForKey:kSBThreshold]);
        params.prior=((float)[defaults floatForKey:kSBPrior]);
        params.sigma=((float)[defaults floatForKey:kSBSigma]);
        params.sbRayNumber=((int)[defaults integerForKey:kSBNumberOfRays]);
        params.degreeOffset=((int)[defaults integerForKey:kSBDegreeOffset]);

        [self.processor setParameter:&params];
        
        NSLog(@"[Waning] The processor does not pick up these parameter just yet.");
        NSLog(@"Prior = %f", params.prior);
        NSLog(@"sigma = %f", params.sigma);
        NSLog(@"threshold = %f", params.threshold);
        
    
        self.processor.outputFaceFileName = [ObjCAdapter getOutputFilePath: self.model.getFaceMetaFileName];
        self.processor.outputPupilFileName = [ObjCAdapter getOutputFilePath: self.model.getPupilFileName];
        
        
        [self.videoManager start];
        [self.processor start];
        [self initVideoWriter];
    }

}


-(void)closeSystem
{
    if([self.processor isStarted])
    {
        [self.processor stop];
        videoWriter.close();
        
    }
}


-(void)initVideoWriter
{
    
    NSString* fileName = self.model.getFaceVideoFileName;
    
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
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"v511.mp4"];
    [self.videoManager open:filePath];
    /*----------------------------------------------------------------------------------------*/
    
    
    // remove the view's background color
    self.view.backgroundColor = nil;
    
    
    __block typeof(self) blockSelf = self;
    
    [self.videoManager setProcessBlock:^(const cv::Mat& cvFrame){
        
        if (![blockSelf.processor isStarted]) {
            return cvFrame;
        }
        
        // if the vidoe is done?
        if (cvFrame.empty()) {
            [blockSelf closeSystem];
            return cvFrame;
        }
        
        cv::Mat returnFrame = cvFrame;
        
        blockSelf->videoWriter << cvFrame;

        [blockSelf updateUI: [blockSelf.processor hasFace]];


        /* Put data to shared memory */
        {
            [blockSelf.processor addFrame:cvFrame
                          withFrameNumber:blockSelf.currentFrameNumber ];
            
            returnFrame = [blockSelf.processor getDebugFrame];
            
            // NSLog(@">> add %lu", (unsigned long)blockSelf.currentFrameNumber);

        }

        
        [blockSelf advanceFrame];
        
        
//        NSLog(@"spf %f", blockSelf->mainClock.getTime());
//        blockSelf->mainClock.reset();
        
        return returnFrame;
     
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
    

    if ([self.model.bridgeDelegate isNumberStarted]) {
        
        if (self.model.numberStartFrame <= 0) {
            NSLog(@"Start Number %lu", (unsigned long)self.currentFrameNumber);
            self.model.numberStartFrame = self.currentFrameNumber;
        }
    }
    
    if ([self.model.bridgeDelegate isNumberStoped]) {
        
        if(self.model.numberStopFrame <= 0){
            NSLog(@"stop Number %lu", (unsigned long)self.currentFrameNumber);
            self.model.numberStopFrame = self.currentFrameNumber;
        }
    }
    
//    if ([self.model.bridgeDelegate isTestingFinished]) {
//        
//        [self closeSystem];
//    }
    
}


@end
