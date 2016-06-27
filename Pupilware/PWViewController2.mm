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
#import "Pupilware-Swift.h"

#import "VideoAnalgesic.h"
#import "OpenCVBridge.h"

#import "Libraries/ObjCAdapter.h"

/*---------------------------------------------------------------
 Pupilware Core Header
 ---------------------------------------------------------------*/

#import "PupilwareCore/PupilwareController.hpp"
#import "PupilwareCore/Algorithm/IPupilAlgorithm.hpp"
#import "PupilwareCore/Algorithm/MDStarbustNeo.hpp"
#import "PupilwareCore/ImageProcessing/SimpleImageSegmenter.hpp"

#import "PupilwareCore/IOS/IOSFaceRecognizer.h"

/*---------------------------------------------------------------
 Objective C Header
 ---------------------------------------------------------------*/

@interface PWViewController2 ()

@property (strong, nonatomic) VideoAnalgesic *videoManager;
@property (strong, nonatomic) IOSFaceRecognizer *faceRecognizer;

- (IBAction)startBtnClicked:(id)sender;

@end


@implementation PWViewController2
{
    std::shared_ptr<pw::PupilwareController> pupilwareController;
    std::shared_ptr<pw::MDStarbustNeo> pwAlgo;
    
    std::vector<std::vector<float>> results;
    bool hasStarted;
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
}


/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////    Objective C Implementation     /////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////

- (void) initSystem
{
    [self initVideoManager];
    [self initPupilwareCtrl];
}


-(void)initPupilwareCtrl
{
    
    hasStarted = false;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
    const char *filePath = [path cStringUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"%s", filePath);
    
    pupilwareController = pw::PupilwareController::Create();
    pwAlgo = std::make_shared<pw::MDStarbustNeo>("StarbustNeo");
    
    pupilwareController->setPupilSegmentationAlgorihtm( pwAlgo );
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
        
        return [weakSelf _processCameraImage:cameraImage
                                     context:weakSelf.videoManager.ciContext];
        
    }];

}


/* 
 * This function will be called in sided Video Manager callback.
 * It's used for process a camera image with Pupilware system.
 */
-(CIImage*)_processCameraImage:(CIImage*)cameraImage context:(CIContext*)context
{
    
    cv::Mat cvFrame = [ObjCAdapter IGImage2Mat:cameraImage
                                   withContext:context];
    
    /* The source image is upside down, so It need to be rotated up. */
    [ObjCAdapter Rotate90:cvFrame withFlag:1];
    
    auto faceMeta = [self.faceRecognizer recognize:cameraImage];
    
    /* 
     * Since we use iOS Face Recongizer, we need inject nessary data
     * to thePupilware to work with.
     */
    pupilwareController->setFaceMeta(faceMeta);
    
    /* Process the rest of the work (e.g. pupil segmentation..) */
    pupilwareController->processFrame(cvFrame);
    
    
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
    
    if(!debugImg.empty()){
        
        cv::Mat debugEyeImg = pwAlgo->getDebugImage();
        
        /* Combind 2 debug images into one*/
        if(!debugEyeImg.empty()){
            cv::resize(debugEyeImg, debugEyeImg, cv::Size(debugImg.cols, debugEyeImg.rows*2));
            debugEyeImg.copyTo(debugImg(cv::Rect(0, 0, debugEyeImg.cols, debugEyeImg.rows)));
        }
        
    }
    
    return debugImg;
}



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
    }
    else
    {
        pupilwareController->start();
    }
}



@end
