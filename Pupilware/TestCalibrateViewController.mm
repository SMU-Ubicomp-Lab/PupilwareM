//
//  TestCalibrateViewController.m
//  CogSense
//
//  Created by Sohail Rafiqi on 3/10/16.
//  Copyright © 2016 SMU. All rights reserved.
//

#import "TestCalibrateViewController.h"
#import "APLGraphView.h"
#import <opencv2/videoio/cap_ios.h>
#import "PWPupilProcessor.hpp"
#import "DisplayDataViewController.h"
#import "CalibrationResultViewController.h"
#import "PWUtilities.h"
#import "MyCvVideoCamera.h"
#import "Pupilware-Swift.h"

#import "constants.h"
#import "VideoAnalgesic.h"
#import "OpenCVBridge.h"
#import "NMSimplex.h"

@class commandControl;
@class DataModel;
// @class VideoDisplayViewController;

using namespace cv;
using namespace std;

NSString *leftOutputVideoFileName = @"";
NSString *rightOutputVideoFileName = @"";

NSString *leftCalbFileName = @"";
NSString *rightCalbFileName = @"";
NSString *timeStampValue;
std::vector<float> result;


@interface TestCalibrateViewController () <CvVideoCameraDelegate>

    @property (strong,nonatomic) VideoAnalgesic *videoManager;
    @property (weak, nonatomic) IBOutlet UILabel *meanPupilSize;
    @property (weak, nonatomic) IBOutlet UIButton *myStartButton;
    @property (weak, nonatomic) IBOutlet UILabel *experimentTitle;
    @property (strong,nonatomic) DataModel *model;

    @property (weak, nonatomic) IBOutlet APLGraphView *graphView;
    @property (weak, nonatomic) IBOutlet UIWebView *gameView;
    @property (nonatomic) NSInteger iterationCounter;
    @property (strong, nonatomic) NSMutableArray* parameters;
    @property (strong, nonatomic) NSMutableArray* imageProcessingParams;
    @property (strong, nonatomic) NSMutableArray* postProcessingParams;


    @property (strong, nonatomic) NSMutableArray* pickedMutations;
    @property (strong, nonatomic) NSMutableArray* postProcPickedMutations;





@end

@implementation TestCalibrateViewController
{
    PWPupilProcessor *processor;
    AVAudioPlayer *audioPlayer;
    bool isFinished;
    //UIView *imageView;
   // NSString *participantID;
    
    std::vector<std::vector<float>> results;
    std::vector<float> stdValues;
    std::vector<float> baselineValues;
    
    bool isStarted;
}

//// Post processing index of possible variables
const int kmWindow = 0;
const int kgWindow = 1;


-(DataModel*)model{
    if(!_model){
        _model = [DataModel sharedInstance];
    }
    return _model;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    timeStampValue = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
    NSLog(@"TimeStamp at the start %@", timeStampValue);
    
    self.iterationCounter = 0;
    self.numberOfIteration = 60;
    isFinished = false;

    
       if(!self.isCalibCogMax)
            {
                const float kCaptureBaselineTime = 10.0f;  //Allow 10 secs to collect frames before analysis data
                [NSTimer scheduledTimerWithTimeInterval:kCaptureBaselineTime
                                                 target:self
                                               selector:@selector(finishTheIteration)
                                               userInfo:nil
                                                repeats:NO];
            }


    [self loadCamera];
    [self preparePupilProcessor];
    // Do any additional setup after loading the view.
}

-(void)finishTheIteration
{
    isFinished = true;
    // NSLog(@"Inside finish iteration");

    // I commented the following statement out as it makes no sense to process to determine the pupil
    // size of the images captured through camera. We wanted to save this and perform extract operations
    // using different parameters. If this is incorrect then we will uncomment it out.
    
    //[self processData];
    
    if(self.iterationCounter == self.numberOfIteration-1){
        NSLog(@"FINISH");
    }
    
    // Closing the video camera after the first iteration.
    processor->closeCapture();
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(![self.videoManager isRunning])
        [self.videoManager start];
}


-(void)viewWillDisappear:(BOOL)animated
{
    if([self.videoManager isRunning])
        [self.videoManager stop];
    
    [super viewWillDisappear:animated];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(VideoAnalgesic*)videoManager{
    if(!_videoManager){
        _videoManager = [VideoAnalgesic captureManager];
        _videoManager.preset = AVCaptureSessionPresetMedium;
        [_videoManager setCameraPosition:AVCaptureDevicePositionFront];
    }
    return _videoManager;
    
}

-(void)loadSettingToProcessor
{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    processor->eyeDistance_ud       = self.model.getDist;
    processor->windowSize_ud        = self.model.getMovAvg;
    processor->mbWindowSize_ud      = self.model.getmedBlur;
    processor->baselineStart_ud     = self.model.getBaseStart;
    processor->baselineEnd_ud       = self.model.getBaseEnd;
    processor->threshold_ud         = self.model.getThresh;
    processor->markCost             = self.model.getMarkCost;
    processor->baseline             = self.model.getBaseline;
    processor->cogHigh              = self.model.getCogHigh;

    // initial parameter grid
    self.parameters = [NSMutableArray new];
    self.postProcessingParams = [NSMutableArray new];
    
    
   // Post processing parameters
    
//    NSMutableArray* postProcessingPossibleMutations = [[NSMutableArray alloc] init];
//    self.postProcPickedMutations = [[NSMutableArray alloc]init];
//
//
//    for (NSNumber *mwindowSize in self.postProcessingParams[kmWindow])
//        for (NSNumber *gwindowSize in self.imageProcessingParams[kgWindow])
//                {
//                    [postProcessingPossibleMutations addObject:@[
//                                                    mwindowSize,
//                                                    gwindowSize
//                                                     ]];
//                }
//    
//    
//    int postProcN = [postProcessingPossibleMutations count];
//    
//    NSLog(@"Total post processing possible mutation %d", postProcN);
//    
//    for (int i=0; i < postProcN; i++) {
//        NSUInteger randomIndex = arc4random() % [postProcessingPossibleMutations count];
//        [postProcessingPossibleMutations exchangeObjectAtIndex:i withObjectAtIndex:randomIndex];
//    }
//    self.postProcPickedMutations = postProcessingPossibleMutations;
}

//-(void)processData
//{
//    
//    processor->process_signal();
//    
//    if(self.isCalibCogMax) // isCalibCogMax never assigned ?
//    {
//        std::vector<float> result = processor->getResultGraph();
//        [self openResultView];
//    }
//    else
//    {
//        dispatch_async(dispatch_get_main_queue(),^{
//            [self.model.bridgeDelegate trackingFaceDone];
//        });
//        result = processor->getPupilPixel();
//        results.push_back(result);
//        
//        float stdV = calStd(result);
//        float madV = calMad(result);
//        
//        stdValues.push_back(stdV);
//        
//        
//        float currentBaseline = processor->calBaselineFromCurrentSignal();
//        baselineValues.push_back(currentBaseline);
//        
//        NSLog(@"STD is %f : MAD is %f", stdV, currentBaseline);
//    }
//}

- (void) writeResultsToFile:(vector<std::vector<float>>) data
{
    NSString *featureFile;
    NSFileHandle *fileHandle;
    
    
    NSString *docDir = NSSearchPathForDirectoriesInDomains(
                                                           NSDocumentDirectory,
                                                           NSUserDomainMask, YES
                                                           )[0];
    
    featureFile = [docDir
                   stringByAppendingPathComponent:
                   [NSString stringWithFormat:@"%@_Results.csv", self.model.getCalibrationData]];
    
    // featureFile = [docDir stringByAppendingPathComponent:self.model.getCalibrationData];
    
    if  (![[NSFileManager defaultManager] fileExistsAtPath:featureFile]) {
        [[NSFileManager defaultManager]
         createFileAtPath:featureFile contents:nil attributes:nil];
    }
    
    fileHandle = [NSFileHandle
                  fileHandleForUpdatingAtPath:featureFile];

    for( int i=0; i< (int)data.size(); i++ )
    {
        for( size_t j=0; j< (size_t)data[i].size(); j++ )
        {
            
            NSString *text=[NSString stringWithFormat:@"%f,",data[i][j]];
            
            [fileHandle writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
        }
        NSString *text=[NSString stringWithFormat:@"\n"];
        
        [fileHandle writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
    }
}


- (IBAction)showResult:(id)sender
{
    processor->closeCapture();
    
    // NSLog(@"Calling openresultview from SHOW RESULT");
    [self openResultView];
}

-(void)openResultView
{
    
  //  NSLog(@"Inside openresult view");
    [self viewWillDisappear:YES]; // Added this to stop calibration. Probably not the best way to do this.
    
    //
    
    NSString *calibrationParamFile;
    NSFileHandle *paramFileHandle;
    
    
    NSString *docDir = NSSearchPathForDirectoriesInDomains(
                                                           NSDocumentDirectory,
                                                           NSUserDomainMask, YES
                                                           )[0];

    
     calibrationParamFile = [docDir stringByAppendingPathComponent:self.model.getCalibrationParams];
    
    if  (![[NSFileManager defaultManager] fileExistsAtPath:calibrationParamFile]) {
        [[NSFileManager defaultManager]
         createFileAtPath:calibrationParamFile contents:nil attributes:nil];
    }
    
    paramFileHandle = [NSFileHandle
                  fileHandleForUpdatingAtPath:calibrationParamFile];
    

    if(self.isCalibCogMax)
    {
        CalibrationResultViewController *distVC = [self.storyboard
                                                   instantiateViewControllerWithIdentifier:@"cbSummaryVC"];
        
        if(distVC != nil)
        {
            distVC.dataPoints = vector2NSArray(processor->getResultGraph());
            distVC.thePeak = @(processor->getResultPeak());
            distVC.isCalibMax = YES;
            [self presentViewController:distVC animated:YES completion:nil];
        }
        
    }
    else
    {
        if (results.size() < self.numberOfIteration)
        {
            NSLog(@"It is not fully calibrated");
            return;
        }
        
         NSArray* madValues = vector2NSArray(stdValues);
        // NSLog(@"MadValues %@",madValues);
        
        NSNumber* minvalue =[madValues valueForKeyPath:@"@min.floatValue"];
        NSUInteger indexOfMinValue = [madValues indexOfObject:minvalue];
        
        if (indexOfMinValue>[self.pickedMutations count]) {
            NSLog(@"Error: min value out of bound %d", indexOfMinValue);
            return;
        }
        
        NSLog(@"Value %@, Index %d",minvalue, indexOfMinValue);
        NSLog(@"%@",self.pickedMutations[indexOfMinValue]);
        
        for( int i=0;i<= self.numberOfIteration;i++)
        {
           // NSLog(@"size %@; paramiter %@",madValues[i], self.pickedMutations[i]);
            NSString *text=[NSString stringWithFormat:@"%@\n",self.pickedMutations[i]];
            
            [paramFileHandle writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        timeStampValue = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
        NSLog(@"TimeStamp at the end %@", timeStampValue);
    }
}


-(BOOL)getVideoFrame:(Mat&)leftOutFrame rightEye:(Mat&) rightOutFrame
{
    Mat leftVideoFrame, rightVideoFrame;
    VideoCapture tmpcapture;
    
    tmpcapture = processor->getVideoDevice("leftEye");
    tmpcapture = processor->getVideoDevice("rightEye");
    
    processor->getVideoDevice("leftEye") >> leftVideoFrame;
    processor->getVideoDevice("rightEye") >> rightVideoFrame;
    
    if(!leftVideoFrame.empty() and !rightVideoFrame.empty())
    {
        leftOutFrame = leftVideoFrame;
        rightOutFrame = rightVideoFrame;
        // NSLog(@"Returning Yes");
        return YES;
    }
    // NSLog(@"Returning NO");
    return NO;
}

-(void)loadVideoFrames
{
    
    processor->clearData();
    
    TermCriteria  	termcrit = TermCriteria(TermCriteria::MAX_ITER+TermCriteria::EPS, 50, 0.000001);
    //Apply Nelder Mead Search to find the best parameters
    cv::Ptr<cv::DownhillSolver> solver=cv::DownhillSolver::create();
    cv::Ptr<NMSimplex> ptr_F = cv::makePtr<NMSimplex>();
    
    ptr_F->setUp(processor);
    
    cv::Mat x=(cv::Mat_<double>(1,3)<<10.0,15.0, 20.0),
    step=(cv::Mat_<double>(3,1)<<5.0, 5.0, 5.0);
    //etalon_x=(cv::Mat_<double>(1,2)<<-0.0,0.0);
    //double etalon_res=0.0;
    solver->setFunction(ptr_F);
    solver->setInitStep(step);
    solver->setTermCriteria(termcrit);
    double res=solver->minimize(x);
    
    NSLog(@"Dump x %f", x.at<double>(0, 0));
    NSLog(@"Dump x %f", x.at<double>(0, 1));
    NSLog(@"Dump x %f", x.at<double>(0, 2));
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger: x.at<double>(0,0) forKey:@"s_threshold"];
    [defaults setInteger: x.at<double>(0,1) forKey:@"s_markCost"];
    [defaults setInteger: x.at<double>(0,2) forKey:@"s_intensityThreshold"];
    
    [defaults synchronize];

    isFinished = true;
    
    //[self writeResultsToFile:results];
}


-(BOOL)prepareVideoLoad
{
    isFinished = false;
    processor->isShouldWriteVideo = false;
    processor->isShouldDetectFace = false;
    
    [self loadVideoFrames];
    return NO;
}


- (void)loadCamera
{
    
    // remove the view's background color
    self.view.backgroundColor = nil;
    
   //  NSLog(@"Inside the Load Camera");
    
    __weak typeof(self) weakSelf = self;
    
    __block NSDictionary *opts = @{CIDetectorAccuracy: CIDetectorAccuracyLow, CIDetectorEyeBlink:@YES};
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:self.videoManager.ciContext options:opts];
    
    Mat leftEyeImage, rightEyeImage, tmpLeftEyeImage, tmpRightEyeImage;

    
    // Following block of code gets the image from the camera and calls OpenCVBridge. If either of the eyes
    // are closed, then skip the frame.
    
    [self.videoManager setProcessBlock:^(CIImage *cameraImage){
        
        // NSLog(@"Inside the loop");
        
        opts = @{CIDetectorImageOrientation:@6};
        
        NSArray *faceFeatures = [detector featuresInImage: cameraImage options:opts];
        
        
        if (isFinished)
        {
            if (self.isCalibCogMax) // isCalibCogMax never aasigned ?
            {
//                isStarted = false;
//                dispatch_async(dispatch_get_main_queue(),^{
//                    [self processData];
//                });
            }
            else
            {
                if(![self prepareVideoLoad])

                {
                    // Finished ALL iterations
                    // NSLog(@"Finished all iterations -- Calling openresultview from under advance iteration ");
                    
                    isStarted = false;
                    dispatch_async(dispatch_get_main_queue(),^{
                        [self openResultView];
                    });

                    dispatch_async(dispatch_get_main_queue(),^{
                        [self.model.bridgeDelegate finishCalibration];
                    });
                }
            }
        }
        else  //Collect frames used for later calibration
        {
                // Processing image from the camera.
                for(CIFaceFeature *face in faceFeatures ){
                    if(!face.leftEyeClosed && ! face.rightEyeClosed){
                        // NSLog(@"Calling opencv bridge");
                        cameraImage = [OpenCVBridge OpenCVTransferAndReturnFaces:face usingImage:cameraImage andContext:weakSelf.videoManager.ciContext andProcessor:(processor) andLeftEye:face.leftEyePosition andRightEye:face.rightEyePosition andIsFinished:isFinished];
                    }
                }
        }
        
        // NSLog(@"REPEATING");
        
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           self.meanPupilSize.text = [NSString stringWithFormat:@"Pupil Size: %f",
                                                      processor->getPupilSize()];
                       });
    
        
        return cameraImage;

    }];
    
    // NSLog(@"Outside the block");
}

-(NSString*)getOutputFilePath:(NSString*) outputFileName
{
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                            NSUserDomainMask,
                                                            YES)
                        objectAtIndex:0];
    
    NSString *outputFilePath = [docDir stringByAppendingPathComponent: outputFileName];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // OpenCV.open does not work with file that is already existed.
    // So, if there is, it needs to be deleted.
    NSError *error;
    [fm removeItemAtPath:outputFilePath error:&error];
    
    return outputFilePath;
}


-(void)preparePupilProcessor
{

    // Do not want to run the process until pressing start.
    isFinished = false;
    isStarted = false;

    if( !processor )
    {

        [self.model setNewCalibrationFiles];
        leftOutputVideoFileName =self.model.getCalibrationLeftEye;
        rightOutputVideoFileName =self.model.getCalibrationRightEye;

        leftCalbFileName = [self getOutputFilePath:leftOutputVideoFileName];
        rightCalbFileName = [self getOutputFilePath:rightOutputVideoFileName];

        processor = new PWPupilProcessor([leftCalbFileName UTF8String], [rightCalbFileName UTF8String]);
        processor->isShouldWriteVideo = true;

        [self loadSettingToProcessor];
    }
    
}

NSArray* vector2NSArray( std::vector<float> v )
{
    if(v.size() <= 0 )
        return nil;
    
    float percentTrim = 0.05;
    int trimSize = v.size()*percentTrim;
    
    NSMutableArray *buffer = [[NSMutableArray alloc] init];
    for( int i=trimSize; i<v.size()-trimSize; i++)
    {
        [buffer addObject:@(v[i])];
    }
    
    return [NSArray arrayWithArray:buffer];
}

@end
