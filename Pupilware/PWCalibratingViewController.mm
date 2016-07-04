//
//  PWCalibratingViewController
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/24/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

#import "PWCalibratingViewController.h"
#import <opencv2/videoio/cap_ios.h>

#import "MyCvVideoCamera.h"
#import "VideoAnalgesic.h"
#import "Libraries/ObjCAdapter.h"

#import "Pupilware-Swift.h"
#import "constants.h"

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
#import "pupilwareCore/SignalProcessing/SignalProcessingHelper.hpp"
#import "PupilwareCore/IOS/IOSFaceRecognizer.h"

#import "PupilwareCore/PWVideoWriter.hpp"
#import "PupilwareCore/PWCSVExporter.hpp"

/*---------------------------------------------------------------
 Objective C Header
 ---------------------------------------------------------------*/

@interface PWCalibratingViewController ()


@property (strong, nonatomic) VideoAnalgesic *videoManager;         /* Manage iOS Video input      */
@property (strong, nonatomic) IOSFaceRecognizer *faceRecognizer;    /* recognize face from ICImage */
@property (strong,nonatomic) DataModel *model;                      /* Connect with Swift UI       */

@property NSUInteger currentFrameNumber;
@property Boolean    calibrating;

- (IBAction)startBtnClicked:(id)sender;

@end


@implementation PWCalibratingViewController
{
    std::shared_ptr<pw::PupilwareController> pupilwareController;
    std::shared_ptr<pw::MDStarbustNeo> pwAlgo;

    pw::PWVideoWriter videoWriter;
    pw::PWCSVExporter csvExporter;
    
    std::vector<cv::Mat> videoFrameBuffer;
    std::vector<pw::PWFaceMeta> faceMetaBuffer;
    
}

/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////    Instantiation    //////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////

-(VideoAnalgesic*)videoManager{
    if(!_videoManager){
        _videoManager = [VideoAnalgesic captureManager];
        _videoManager.preset = AVCaptureSessionPresetMedium;
        [_videoManager setCameraPosition:AVCaptureDevicePositionFront];

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
    [self startCalibrating];

}


-(void)viewWillDisappear:(BOOL)animated
{
    [self stopVideoManager];
    [self stopCalibrating];
    
    [super viewWillDisappear:animated];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (IBAction)startBtnClicked:(id)sender {
    
    [self toggleBuffering];
    
    if(self.calibrating)
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


-(void) toggleBuffering{
    
    if(self.calibrating)
    {
        [self stopCalibrating];
    }
    else
    {
        [self startCalibrating];
    }

}


-(void) startCalibrating
{
    if(!self.calibrating)
    {
        self.currentFrameNumber = 0;
        self.calibrating = true;
        
        [self clearBuffer];
        

        // Only capture for kCaptureBaselineTime seconds
        [NSTimer scheduledTimerWithTimeInterval:kCalibrationDuration
                                         target:self
                                       selector:@selector(stopCalibrating)
                                       userInfo:nil
                                        repeats:NO];
        
        
    }
}


-(void) stopCalibrating
{
    if(self.calibrating)
    {
        self.calibrating = false;
        
        [self calibrate];
        
        [self.model.bridgeDelegate finishCalibration];
        
        [self clearBuffer];
        
    }
}


- (void) initSystem
{
    [self initVideoManager];
    
    [self.model setNewCalibrationFiles];
    
    [self initPupilwareCtrl];
    
    

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
    

    // TODO: Load default setting
    
    /* Load Initial Setting to the Pupilware Controller*/
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    
//    pwAlgo->setThreshold((float)[defaults floatForKey:kSBThreshold]);
//    pwAlgo->setPrior((float)[defaults floatForKey:kSBPrior]);
//    pwAlgo->setSigma((float)[defaults floatForKey:kSBSigma]);
//    pwAlgo->setRayNumber((int)[defaults integerForKey:kSBNumberOfRays]);
//    pwAlgo->setDegreeOffset((int)[defaults integerForKey:kSBDegreeOffset]);
    
    
//    processor->windowSize_ud        = (int)[defaults integerForKey:kWindowSize];
//    processor->mbWindowSize_ud      = (int)[defaults integerForKey:kMbWindowSize];
//    processor->eyeDistance_ud       = self.model.getDist;
//    processor->baselineStart_ud     = self.model.getBaseStart;
//    processor->baselineEnd_ud       = self.model.getBaseEnd;
//    processor->baseline             = self.model.getBaseline;
//    processor->cogHigh              = self.model.getCogHigh;
//    
//    // Following four parameters are optimal parameters resulting from the calibration process
//    //
//    
//    NSLog(@"Default values in PWViewCOntroller");
//    NSLog(@"Eye Distance %f, window size %d, mbWindowsize %d, baseline start %d, basline end %d, threshold %d, mark cost %d, Baseline %f, coghigh %f", processor->eyeDistance_ud, processor->windowSize_ud, processor->mbWindowSize_ud, processor->baselineStart_ud, processor->baselineEnd_ud, processor->threshold_ud, processor->markCost, processor->baseline, processor->cogHigh);
    
}



- (void)initVideoManager
{
    // remove the view's background color
    self.view.backgroundColor = nil;
    
    
    /* Use IOS Face Recoginizer */
    self.faceRecognizer = [[IOSFaceRecognizer alloc] initWithContext:self.videoManager.ciContext];
    
    
    __weak typeof(self) weakSelf = self;
    
    
    [self.videoManager setProcessBlock:^(CIImage *cameraImage){
        
        
        auto returnImage = [weakSelf _segmentFaceAndBuffering:cameraImage
                                                  frameNumber:weakSelf.currentFrameNumber
                                                      context:weakSelf.videoManager.ciContext];
        
        weakSelf.currentFrameNumber += 1;
        
        return returnImage;
     
    }];

}


/* 
 * This function will be called in sided Video Manager callback.
 * It's used for process a camera image with Pupilware system.
 */
-(CIImage*)_segmentFaceAndBuffering:(CIImage*)cameraImage
                   frameNumber:(NSUInteger)frameNumber
                       context:(CIContext*)context
{
  
    if (!self.calibrating) {
        return cameraImage;
    }
    
    /* The source image is in sideway (<-), so It need to be rotated back up. */
    CGAffineTransform transform = CGAffineTransformMakeRotation(-M_PI_2);
    transform = CGAffineTransformTranslate(transform,-480,0);
    cameraImage = [cameraImage imageByApplyingTransform:transform];
    
    
    cv::Mat cvFrame = [ObjCAdapter IGImage2Mat:cameraImage
                                   withContext:context];

    
    
    /* 
     * Since we use iOS Face Recongizer, we need to inject faceMeta manually.
     */
    auto faceMeta = [self.faceRecognizer recognize:cameraImage];
    faceMeta.setFrameNumber( (int) self.currentFrameNumber);
    

    videoFrameBuffer.push_back(cvFrame);
    faceMetaBuffer.push_back( faceMeta );
    
    cv::rectangle(cvFrame, faceMeta.getFaceRect(), cv::Scalar(255,0,100));
    [ObjCAdapter Rotate90:cvFrame withFlag:2];
    
    CIImage* returnImage = [ObjCAdapter Mat2CGImage:cvFrame
                                        withContext:context];
    
    return returnImage;
}





-(void) calibrate
{
    // !!! Buffering the entire frame consume a lot of memory
    // Well, for 10 secs, it uses about 180Mb. Not too bad actually.
    
    /* It is just a platholder of running calibration for 3 iterations.
     * It will be replaced with Optimizat algorithm
     */
    NSArray *ths = @[@0.005, @0.1, @0.24];
    NSArray *priors = @[@1, @1.2, @1.5];
    NSArray *sigmas = @[@5, @6, @8];
    
    for (int j=0; j<3; ++j) {
    
        if(!pupilwareController->hasStarted())
        {
            /* init pupilware stage */
            pupilwareController->start();
            
            // TODO set init parameter for each iteration here.
            pwAlgo->setThreshold([ths[j] floatValue]);
            pwAlgo->setPrior([priors[j] floatValue]);
            pwAlgo->setSigma([sigmas[j] floatValue]);
            
            for (int i=0; i<videoFrameBuffer.size(); ++i) {
                pupilwareController->setFaceMeta(faceMetaBuffer[i]);
                pupilwareController->processFrame(videoFrameBuffer[i], i);
            }
            
            
            auto rawPupilSizes = pupilwareController->getRawPupilSignal();
            NSLog(@"[%d] Pupil Signal Size %lu", j, rawPupilSizes.size());
            
            auto std = cw::calStd(rawPupilSizes);
            NSLog(@"STD is %f", std);
            
            // TODO Store list of std for testing ?
            
            /* clear stage and do processing */
            pupilwareController->stop();
        
        }
    
    }
    
    // - return best parameter set.
    // - write the setting to files.

}


-(void)clearBuffer{
    videoFrameBuffer.clear();
    faceMetaBuffer.clear();
}

@end
