//
//  PWViewController2.m
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/24/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

#import "PWViewController2.h"
#import <opencv2/videoio/cap_ios.h>

#import "MyCvVideoCamera.h"
#import "VideoAnalgesic.h"
#import "Libraries/ObjCAdapter.h"

/*---------------------------------------------------------------
 Pupilware Core Header
 ---------------------------------------------------------------*/
#import "PupilwareCore/preHeader.hpp"
#import "PupilwareCore/PupilwareController.hpp"
#import "PupilwareCore/Algorithm/IPupilAlgorithm.hpp"
#import "PupilwareCore/Algorithm/MDStarbustNeo.hpp"
#import "PupilwareCore/ImageProcessing/SimpleImageSegmenter.hpp"
#import "PupilwareCore/IOS/IOSFaceRecognizer.h"

#import "PupilwareCore/PWVideoWriter.hpp"
#import "PupilwareCore/PWCSVExporter.hpp"

/*---------------------------------------------------------------
 Objective C Header
 ---------------------------------------------------------------*/

@interface PWViewController2 ()

@property (strong, nonatomic) VideoAnalgesic *videoManager;
@property (strong, nonatomic) IOSFaceRecognizer *faceRecognizer;

@property NSUInteger currentFrameNumber;

- (IBAction)startBtnClicked:(id)sender;

@end


@implementation PWViewController2
{
    std::shared_ptr<pw::PupilwareController> pupilwareController;
    std::shared_ptr<pw::MDStarbustNeo> pwAlgo;
    
    pw::PWVideoWriter videoWriter;
    pw::PWCSVExporter csvExporter;
    
    std::vector<std::vector<float>> results;
}


-(VideoAnalgesic*)videoManager{
    if(!_videoManager){
        _videoManager = [VideoAnalgesic captureManager];
        _videoManager.preset = AVCaptureSessionPresetMedium;
        [_videoManager setCameraPosition:AVCaptureDevicePositionFront];

    }
    return _videoManager;
    
}

/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////    UI View Events     /////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self initSystem];
    
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self startVideoManager];
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
        pupilwareController->stop();
        videoWriter.close();
        csvExporter.close();
    }
    else
    {
        pupilwareController->start();
        self.currentFrameNumber = 0;
        
        [self initVideoWriter];
        [self initCSVExporter];
    }

}


- (void) initSystem
{
    [self initVideoManager];
    [self initPupilwareCtrl];

}




-(void)initVideoWriter
{
    
    // TODO: use the real user id as a file name.
    auto fileName = [NSString stringWithFormat:@"face%ld.mp4", (long)[[NSDate date] timeIntervalSince1970]];
    
    NSString* videoPath = [ObjCAdapter getOutputFilePath: fileName];
    
    // TODO: change it to iPhone6s Frame Size.
    cv::Size frameSize (480,360);
    if(!videoWriter.open([videoPath UTF8String], 30, frameSize))
    {
        NSLog(@"Video Writer is not opened correctedly.");
    }
}

-(void)initCSVExporter
{
    // TODO: use the real user id as a file name.
    auto fileName = [NSString stringWithFormat:@"face%ld.csv", (long)[[NSDate date] timeIntervalSince1970]];
    
    NSString* filePath = [ObjCAdapter getOutputFilePath: fileName];
    
    csvExporter.open([filePath UTF8String]);
}

-(void)initPupilwareCtrl
{
    
    self.currentFrameNumber = 0;
    
    pupilwareController = pw::PupilwareController::Create();
    pwAlgo = std::make_shared<pw::MDStarbustNeo>("StarbustNeo");
    
    pupilwareController->setPupilSegmentationAlgorihtm( pwAlgo );
    
    /*! 
     * If there is no a face segmentation algorithm,
     * we have to manually give Face Meta data to the system.
     */
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
//    const char *filePath = [path cStringUsingEncoding:NSUTF8StringEncoding];
//    
//    NSLog(@"%s", filePath);
//    pupilwareController->setFaceSegmentationAlgoirhtm(std::make_shared<pw::SimpleImageSegmenter>(filePath));
    
}


- (void)initVideoManager
{
    // remove the view's background color
    self.view.backgroundColor = nil;
    
    
    /* Use IOS Face Recoginizer */
    self.faceRecognizer = [[IOSFaceRecognizer alloc] initWithContext:self.videoManager.ciContext];
    
    
    __weak typeof(self) weakSelf = self;
    
    
    [self.videoManager setProcessBlock:^(CIImage *cameraImage){
        
        
        auto returnImage = [weakSelf _processCameraImage:cameraImage
                                             frameNumber:weakSelf.currentFrameNumber
                                                 context:weakSelf.videoManager.ciContext];
        
        weakSelf.currentFrameNumber += 1;
        
        return returnImage;
        
        
        //TODO: Enable This block in release built.
        /********************************************
        try{
        
         auto returnImage = [weakSelf _processCameraImage:cameraImage
         frameNumber:weakSelf.currentFrameNumber
         context:weakSelf.videoManager.ciContext];
         
         weakSelf.currentFrameNumber += 1;
         
         return returnImage;
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


/* 
 * This function will be called in sided Video Manager callback.
 * It's used for process a camera image with Pupilware system.
 */
-(CIImage*)_processCameraImage:(CIImage*)cameraImage
                   frameNumber:(NSUInteger)frameNumber
                       context:(CIContext*)context
{
  
    if (!pupilwareController->hasStarted()) {
        return cameraImage;
    }
    
    cv::Mat cvFrame = [ObjCAdapter IGImage2Mat:cameraImage
                                   withContext:context];
    
    videoWriter << cvFrame;
    
    /* The source image is upside down, so It need to be rotated up. */
    [ObjCAdapter Rotate90:cvFrame withFlag:1];
    
    
    /* 
     * Since we use iOS Face Recongizer, we need inject nessary data
     * to thePupilware to work with.
     */
    auto faceMeta = [self.faceRecognizer recognize:cameraImage];
    pupilwareController->setFaceMeta(faceMeta);

    csvExporter << faceMeta;
    
    /* Process the rest of the work (e.g. pupil segmentation..) */
    pupilwareController->processFrame(cvFrame, (int)frameNumber );
    
    
    cv::Mat debugImg = [self _getDebugImage];
    
    if(debugImg.empty()){
        debugImg = cvFrame;
    }
    
    //Rotate it back.
    [ObjCAdapter Rotate90:debugImg withFlag:2];
    
    CIImage* returnImage = [ObjCAdapter Mat2CGImage:debugImg
                                        withContext:context];
    
    
    return returnImage;
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


@end
