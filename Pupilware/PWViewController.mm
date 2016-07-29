//
//  PWViewController.m
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/24/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

#import "PWViewController.h"
#import <opencv2/videoio/cap_ios.h>

#import "PWIOSVideoReader.h"
#import "Libraries/ObjCAdapter.h"

#import "Pupilware-Swift.h"
//#import "constants.h"

@class DataModel;

/*---------------------------------------------------------------
 Pupilware Core Header
 ---------------------------------------------------------------*/
#import "PupilwareCore/preHeader.hpp"
#import "PupilwareCore/PupilwareController.hpp"
#import "PupilwareCore/Algorithm/IPupilAlgorithm.hpp"
#import "PupilwareCore/Algorithm/MDStarbustNeo.hpp"
#import "PupilwareCore/Algorithm/MDStarbust.hpp"
#import "PupilwareCore/ImageProcessing/SimpleImageSegmenter.hpp"
#import "PupilwareCore/IOS/IOSFaceRecognizer.h"

#import "PupilwareCore/PWVideoWriter.hpp"
#import "PupilwareCore/PWCSVExporter.hpp"

/*---------------------------------------------------------------
 Objective C Header
 ---------------------------------------------------------------*/

@interface PWViewController ()

@property (strong, nonatomic) PWIOSVideoReader *videoManager;       /* Manage iOS Video input      */
@property (strong, nonatomic) IOSFaceRecognizer *faceRecognizer;    /* recognize face from ICImage */
@property (strong,nonatomic) DataModel *model;                      /* Connect with Swift UI       */

@property NSUInteger currentFrameNumber;

- (IBAction)startBtnClicked:(id)sender;

@end


@implementation PWViewController
{
    std::shared_ptr<pw::PupilwareController> pupilwareController;
    std::shared_ptr<pw::MDStarbustNeo> pwAlgo;

    pw::PWVideoWriter videoWriter;
    pw::PWCSVExporter csvExporter;
    
    //this block is sharing memory
    cv::Mat currentFrame;
    cv::Mat debugFrame;
    pw::PWFaceMeta faceMeta;
    //----------------------
    
    int count;
    
}

/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////    Instantiation    //////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////

-(PWIOSVideoReader*)videoManager{
    if(!_videoManager){
        _videoManager = [[PWIOSVideoReader alloc] init];

    }
    return _videoManager;
    
}

-(DataModel*)model{
    if(!_model){
        _model = [DataModel sharedInstance];
    }
    return _model;
}


/////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////    UI View Events Handler    /////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initSystem];
    
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self startVideoManager];
    
    [self startPupilware];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [self stopVideoManager];
    
    [super viewWillDisappear:animated];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (IBAction)startBtnClicked:(id)sender {
    
    [self togglePupilware];
    
    if(pupilwareController->hasStarted())
    {
        [sender setTitle:@"Stop" forState: UIControlStateNormal];
    }
    else
    {
        [sender setTitle:@"Start" forState:UIControlStateNormal];
    }
}

- (IBAction)onSaveClicked:(id)sender {
    NSString* filePath = [ObjCAdapter getOutputFilePath:@"pupil.csv"];
    
    auto pupilStorage = pupilwareController->getRawPupilSignal();
    pw::PWCSVExporter::toCSV(pupilStorage, [filePath UTF8String]);
}


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
    
    if(pupilwareController->hasStarted())
    {
        [self stopPupilware];
    }
    else
    {
        [self startPupilware];
    }

}


-(void) startPupilware
{
    if(!pupilwareController->hasStarted())
    {
        pupilwareController->start();
        self.currentFrameNumber = 0;
        
        [self initVideoWriter];
        [self initCSVExporter];
    }
}


-(void) stopPupilware
{
    if(pupilwareController->hasStarted())
    {
        pupilwareController->stop();
        pupilwareController->processSignal();
        pupilwareController->clearBuffer();
        videoWriter.close();
        csvExporter.close();
    }
}


- (void) initSystem
{
    [self initVideoManager];
    [self initPupilwareCtrl];

}



-(void)initVideoWriter
{
    
//    NSString* fileName = self.model.getFaceFileName;
    NSString* fileName = @"face.mp4";
    
    NSString* videoPath = [ObjCAdapter getOutputFilePath: fileName];
    
    cv::Size frameSize (720,1280);
    if(!videoWriter.open([videoPath UTF8String], 30, frameSize))
    {
        NSLog(@"Video Writer is not opened correctedly.");
    }
}


-(void)initCSVExporter
{
    
//    NSString* filePath = [ObjCAdapter getOutputFilePath: self.model.getCSVFileName];
    NSString* filePath = [ObjCAdapter getOutputFilePath: @"face.csv"];
    
    csvExporter.open([filePath UTF8String]);
}


-(void)initPupilwareCtrl
{
    
    self.currentFrameNumber = 0;
    
    pupilwareController = pw::PupilwareController::Create();
    pwAlgo = std::make_shared<pw::MDStarbustNeo>("StarbustNeo");
    
    pupilwareController->setPupilSegmentationAlgorihtm( pwAlgo );
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        while(true){
            
//            int currentFrameN = 0;
//            cv::Mat frame;
//            pw::PWFaceMeta _faceMeta;
//            
//            /* Copy data from shared memory */
//            @synchronized (self) {
//                if( count == self.currentFrameNumber ) continue;
//                if( currentFrame.empty() ) continue;
//                
//                currentFrameN = (int)self.currentFrameNumber;
//                frame = currentFrame.clone();
//                _faceMeta = self->faceMeta;
//                
//            }
//            
//            if (frame.empty()) {
//                continue;
//            }
//            
//    
//                    self->pupilwareController->setFaceMeta(_faceMeta);
//                    /* Process the rest of the work (e.g. pupil segmentation..) */
//                    self->pupilwareController->processFrame(currentFrame, (int)self.currentFrameNumber );
//                    
//                    /* create debug image */
//                    cv::Mat debugImg = [self _getDebugImage];
//                    
//                    if(debugImg.empty()){
//                        debugImg = currentFrame;
//                    }
//                    
//                    self->debugFrame = debugImg.clone();
//            
//            
//                    /* Move to next frame */
////                    [blockSelf advanceFrame];
//
//                    
//                    NSLog(@"process %d, currentFrameNuber %d", count, currentFrameN);
//                    count = currentFrameN;
            
            NSLog(@"----");
            sleep(1);
            
            
        }

    });
    
    /*!
     * If there is no a face segmentation algorithm,
     * we have to manually give Face Meta data to the system.
     */
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
//    const char *filePath = [path cStringUsingEncoding:NSUTF8StringEncoding];
//    
//    NSLog(@"%s", filePath);
//    pupilwareController->setFaceSegmentationAlgoirhtm(std::make_shared<pw::SimpleImageSegmenter>(filePath));
    

    // TODO: Load default setting
    
    /* Load Initial Setting to the Pupilware Controller*/
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    
//    processor->eyeDistance_ud       = self.model.getDist;
//    processor->baselineStart_ud     = self.model.getBaseStart;
//    processor->baselineEnd_ud       = self.model.getBaseEnd;
//    processor->baseline             = self.model.getBaseline;
//    processor->cogHigh              = self.model.getCogHigh;
//    
//    // Following four parameters are optimal parameters resulting from the calibration process
//    
//    processor->windowSize_ud        = (int)[defaults integerForKey:kWindowSize];
//    processor->mbWindowSize_ud      = (int)[defaults integerForKey:kMbWindowSize];
//    processor->threshold_ud         = (int)[defaults floatForKey:kThreshold];
//    processor->markCost             = (int)[defaults floatForKey:kPrior];
//    
//    
//    NSLog(@"Default values in PWViewCOntroller");
//    NSLog(@"Eye Distance %f, window size %d, mbWindowsize %d, baseline start %d, basline end %d, threshold %d, mark cost %d, Baseline %f, coghigh %f", processor->eyeDistance_ud, processor->windowSize_ud, processor->mbWindowSize_ud, processor->baselineStart_ud, processor->baselineEnd_ud, processor->threshold_ud, processor->markCost, processor->baseline, processor->cogHigh);
    
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
    
    
    /* Use IOS Face Recoginizer */
    self.faceRecognizer = [[IOSFaceRecognizer alloc] initWithContext:self.videoManager.ciContext];
    
    
    __block typeof(self) blockSelf = self;
    
    [self.videoManager setProcessBlock:^(const cv::Mat& cvFrame){
        
        
        if (!blockSelf->pupilwareController->hasStarted()) {
            return cvFrame;
        }
        
        cv::Mat returnFrame = cvFrame;

        auto cameraImage = [ObjCAdapter Mat2CIImage:cvFrame
                                        withContext:blockSelf.videoManager.ciContext];
        
        
        
        auto _faceMeta = [blockSelf.faceRecognizer recognize:cameraImage];
        _faceMeta.setFrameNumber( (int)blockSelf.currentFrameNumber );
        
        /* Write data to files*/
        blockSelf->csvExporter << _faceMeta;
        blockSelf->videoWriter << cvFrame;
        
        
        /* Update UI */
        [blockSelf updateUI:_faceMeta.hasFace()];
        

        /* Put data to shared memory */
        @synchronized (blockSelf) {
            blockSelf->currentFrame = cvFrame.clone();
            blockSelf->faceMeta = _faceMeta;
            
            NSLog(@">> add %lu", (unsigned long)blockSelf.currentFrameNumber);
            
//            returnFrame = blockSelf->debugFrame;
        }
        
        /* Update state */
        blockSelf.currentFrameNumber ++;
        
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

/*
 * This function will be called in sided Video Manager callback.
 */
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

-(void) advanceFrame{
    self.currentFrameNumber += 1;
    
    if ([self.model.bridgeDelegate isTestingFinished]) {
        [self stopPupilware];
    }
}

@end
