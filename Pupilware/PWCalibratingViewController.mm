//
//  PWCalibratingViewController.mm
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/24/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

#import "PWCalibratingViewController.h"
#import <opencv2/videoio/cap_ios.h>

#import "MyCvVideoCamera.h"
#import "PWIOSVideoReader.h"
#import "Libraries/ObjCAdapter.h"

#import "Pupilware-Swift.h"
#import "constants.h"
#import "NMSimplex.h"

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
#import "PupilwareCore/PWParameter.hpp"

/*---------------------------------------------------------------
 Objective C Header
 ---------------------------------------------------------------*/

@interface PWCalibratingViewController ()


@property (strong, nonatomic) PWIOSVideoReader *videoManager;       /* Manage iOS Video input      */
@property (strong, nonatomic) IOSFaceRecognizer *faceRecognizer;    /* Recognize face from ICImage */
@property (strong, nonatomic) DataModel *model;                      /* Connect with Swift UI       */
@property (strong, nonatomic) NSTimer*   timer;                      /* Buffering timer*/

@property NSUInteger currentFrameNumber;
@property Boolean    buffering;


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

-(void)initLogging{
    try
    {
        
        NSString* logPath = [ObjCAdapter getOutputFilePath: @"calibration.log"];
        
        FILE* pFile = fopen([logPath UTF8String], "a");
        if(pFile)
        {
            Output2FILE::Stream() = pFile;
            FILELog::ReportingLevel() = logDEBUG4;
        }
    }
    catch(const std::exception& e)
    {
        dlog(logERROR) << e.what();
    }
}


- (void)viewDidLoad {
    
    [super viewDidLoad];

    [self initLogging];
    
    [self initSystem];
    
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self startVideoManager];
    [self startBuffering];

}


-(void)viewWillDisappear:(BOOL)animated
{
    [self stopVideoManager];
    [self clearBuffer];
    
    // Clear timer
    if(self.timer){
        [self.timer invalidate];
        self.timer = nil;
    }
    
    // close files
    [self closeFiles];
    
    [super viewWillDisappear:animated];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (IBAction)startBtnClicked:(id)sender {
    
    [self toggleBuffering];
    
    if(self.buffering)
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
    
    if(self.buffering)
    {
        [self stopBufferingAndCalibrate];
    }
    else
    {
        [self startBuffering];
    }

}


-(void) startBuffering
{
    if(!self.buffering)
    {
        self.currentFrameNumber = 0;
        self.buffering = true;
        
        [self clearBuffer];
        

        // Only capture for kCaptureBaselineTime seconds
        self.timer = [NSTimer scheduledTimerWithTimeInterval:kCalibrationDuration
                                                     target:self
                                                   selector:@selector(stopBufferingAndCalibrate)
                                                   userInfo:nil
                                                    repeats:NO];
        
        
    }
}

-(void) stopBufferingAndCalibrate{
    if(self.buffering)
    {
        
        self.buffering = false;
        
        [self calibrate];
        
        [self clearBuffer];
        
        [self.model.bridgeDelegate finishCalibration];
        
    }
}


- (void) initSystem
{
    dlog(logINFO) << "Init Calibration System";
            
    [self initVideoManager];
    
    // tell swift to create new set of file name
    [self.model setNewCalibrationFiles];
    
    // init writing files modules.
    // They get file names from Swift DataModel
    [self initVideoWriter];
    [self initCSVExporter];
    
    // init Pupilware
    [self initPupilwareCtrl];
    

}

-(void)initVideoWriter
{
    
    NSString* videoPath = [ObjCAdapter getOutputFilePath: self.model.getCalibrationFaceVideoFileName];
    
    cv::Size frameSize (720,1280);
    if(!videoWriter.open([videoPath UTF8String], 30, frameSize))
    {
        NSLog(@"Video Writer is not opened correctedly.");
    }
}


-(void)initCSVExporter
{
    
    NSString* filePath = [ObjCAdapter getOutputFilePath: self.model.getCalibrationDataFileName];
    
    csvExporter.open([filePath UTF8String]);
}

-(void)saveCurrentSettingToFile:(const pw::PWParameter&) param
{
    NSString* filePath = [ObjCAdapter getOutputFilePath: self.model.getCalibrationParamsFileName];
    

    pw::PWCSVExporter::toCSV(param, [filePath UTF8String]);
}


-(void)initPupilwareCtrl
{
    dlog(logINFO) << "Init Pupilware Controller";
    
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
    
    
    __block typeof(self) blockSelf = self;
    
    
    [self.videoManager setProcessBlock:^(const cv::Mat& cvFrame){

        if (!blockSelf.buffering) {
            return cvFrame;
        }
        
        /*
         * Since we use iOS Face Recongizer, we need to inject faceMeta manually.
         */
        auto cameraImage = [ObjCAdapter Mat2CIImage:cvFrame
                                        withContext:blockSelf.videoManager.ciContext];
        auto faceMeta = [blockSelf.faceRecognizer recognize:cameraImage];
        faceMeta.setFrameNumber( (int) blockSelf.currentFrameNumber);
        
        // store the frame in memory
        blockSelf->videoFrameBuffer.push_back(cvFrame);
        blockSelf->faceMetaBuffer.push_back( faceMeta );
        
        // store the frame in files
        blockSelf->videoWriter << cvFrame;
        blockSelf->csvExporter << faceMeta;
        
        
        blockSelf.currentFrameNumber += 1;
        
        return cvFrame;
        
    }];
    

}



-(void) calibrate
{
    // !!! Buffering the entire frame consume a lot of memory
    // Well, for 10 secs, it uses about 180Mb. Not too bad actually.
    
    NSLog(@"Calibrating...");
    
    
    const int kMaxCount = 10;
    const double kEpsilon = 0.000001;
    cv::TermCriteria termcrit = cv::TermCriteria( cv::TermCriteria::MAX_ITER+cv::TermCriteria::EPS, // Type
                                                  kMaxCount,
                                                  kEpsilon );
    
    NSLog(@"NMSimplex : maxCount %d , epsilon %f", kMaxCount, kEpsilon);
    
    //Apply Nelder Mead Search to find the best parameters
    cv::Ptr<cv::DownhillSolver> solver=cv::DownhillSolver::create();
    cv::Ptr<NMSimplex> ptr_F = cv::makePtr<NMSimplex>();
    
    ptr_F->setUp(pupilwareController, pwAlgo);
    ptr_F->setBuffer(videoFrameBuffer, faceMetaBuffer);
 
    // There are just list of default values.
    //    threshold(0.014),
    //    rayNumber(17),
    //    degreeOffset(0),
    //    prior(0.5f),
    //    sigma(0.2f)
    
    const double thresholdInitPoint = 0.014;
    const double sigmaInitPoint = 0.2;
    const double priorInitPoint = 0.5;
    cv::Mat x=(cv::Mat_<double>(1,3)<<thresholdInitPoint, sigmaInitPoint, priorInitPoint);
    
    const double thresholdMovingStep = 0.001;
    const double sigmaMovingStep = 0.01;
    const double priorMovingSteop = 0.05;
    cv::Mat step=(cv::Mat_<double>(3,1)<<thresholdMovingStep, sigmaMovingStep, priorMovingSteop);
    //etalon_x=(cv::Mat_<double>(1,2)<<-0.0,0.0);
    //double etalon_res=0.0;
    
    
    solver->setFunction(ptr_F);
    solver->setInitStep(step);
    solver->setTermCriteria(termcrit);
    solver->minimize(x);
    
    
    pw::PWParameter param;
    param.threshold = x.at<double>(0,0);
    param.sigma = x.at<double>(0,1);
    param.prior = x.at<double>(0,2);
    
    [self saveCurrentSettingToFile: param];

    // Display on log
    NSLog(@"Dump x %f", param.threshold);
    NSLog(@"Dump x %f", param.sigma);
    NSLog(@"Dump x %f", param.prior);
    
    // Save to default
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat: param.threshold forKey:kSBThreshold];
    [defaults setFloat: param.sigma     forKey:kSBSigma];
    [defaults setFloat: param.prior     forKey:kSBPrior];
}


-(void)clearBuffer{
    videoFrameBuffer.clear();
    faceMetaBuffer.clear();
}


-(void)closeFiles{
    
    videoWriter.close();
    csvExporter.close();
    
}

@end
