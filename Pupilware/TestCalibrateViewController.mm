//
//  TestCalibrateViewController.m
//  CogSense
//
//  Created by Sohail Rafiqi on 3/10/16.
//  Copyright © 2016 SMU. All rights reserved.
//

#import "TestCalibrateViewController.h"
#import "APLGraphView.h"
#import <opencv2/highgui/cap_ios.h>
#import "PWPupilProcessor.hpp"
#import "DisplayDataViewController.h"
#import "CalibrationResultViewController.h"
#import "PWUtilities.h"
#import "MyCvVideoCamera.h"
#import "Pupilware-Swift.h"

#import "constants.h"
#import "VideoAnalgesic.h"
#import "OpenCVBridge.h"

@class commandControl;
@class DataModel;
// @class VideoDisplayViewController;

using namespace cv;

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
    //   @property (weak, nonatomic) IBOutlet UIView *imageView;

    @property (weak, nonatomic) IBOutlet APLGraphView *graphView;
    @property (weak, nonatomic) IBOutlet UIWebView *gameView;
    @property (nonatomic) NSInteger iterationCounter;
    @property (strong, nonatomic) NSMutableArray* parameters;

    @property (strong, nonatomic) NSMutableArray* pickedMutations;




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


const int kThreadhold = 0;
const int kPrior = 1;
const int kStd = 2;
const int kmWindow = 3;
const int kgWindow = 4;

-(DataModel*)model{
    if(!_model){
        _model = [DataModel sharedInstance];
    }
    return _model;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
   //  NSLog(@"Inside ViewDid Load of Test Calibrate");

    self.iterationCounter = 0;
    self.numberOfIteration = 6;
    // _model = [DataModel sharedInstance];

    // NSLog(@"Current subject id %@", _model.currentT);
    
    
    
//    [self preparePupilProcessor];
    isFinished = false;
    
       if(!self.isCalibCogMax)
            {
               // NSLog(@"Inside calibrateview: setting timer");
        
                const float kCaptureBaselineTime = 5.0f;
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
    // [self createLoadingView];
    isFinished = true;

    [self processData];
    
    if(self.iterationCounter == self.numberOfIteration-1){
        NSLog(@"FINISH");
    }
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

    
    NSLog(@"Default values in TestViewController ");
    NSLog(@"Eye Distance %f, window size %d, mbWindowsize %d, baseline start %d, basline end %d, threshold %d, mark cost %d, Baseline %f, coghigh %f", processor->eyeDistance_ud, processor->windowSize_ud, processor->mbWindowSize_ud, processor->baselineStart_ud, processor->baselineEnd_ud, processor->threshold_ud, processor->markCost, processor->baseline, processor->cogHigh);

    
    // initial parameter grid
    self.parameters = [NSMutableArray new];
    
    [self.parameters addObject:@[@15,@25,@35]]; // kThreshold
    [self.parameters addObject:@[@1,@2,@3]]; // kPrior
    [self.parameters addObject:@[@1,@1,@1]]; // kstd
    [self.parameters addObject:@[@11,@21,@31]]; // mwindowSize
    [self.parameters addObject:@[@11,@21,@31]]; // gwindowSize
    
    self.pickedMutations = [[NSMutableArray alloc]init];
    
    NSMutableArray* allPosibleMutations = [[NSMutableArray alloc] init];
    
    for (NSNumber *threadhold in self.parameters[kThreadhold])
        for (NSNumber *prior in self.parameters[kPrior])
            for (NSNumber *std in self.parameters[kStd])
                for (NSNumber *mwindowSize in self.parameters[kmWindow])
                    for (NSNumber *gwindowSize in self.parameters[kgWindow])
                        {
                            [allPosibleMutations addObject:@[
                                                             threadhold,
                                                             prior,
                                                             std,
                                                             mwindowSize,
                                                             gwindowSize
                                                             ]];
                        }
    
    
    NSUInteger N = [allPosibleMutations count];
    for (int i; i < N; i++) {
        NSUInteger randomIndex = arc4random() % [allPosibleMutations count];
        [allPosibleMutations exchangeObjectAtIndex:i withObjectAtIndex:randomIndex];
    }
    self.pickedMutations = allPosibleMutations;
    


    //NSLog(@"%@", self.pickedMutations);
    //NSLog(@"%@", self.pickedMutations);
    
    
}

-(void)processData
{
    
    processor->process_signal();
    
    if(self.isCalibCogMax)
    {
        // NSLog(@"Calling openresultview from process Data isCalibCogMax");
        
        std::vector<float> result = processor->getResultGraph();
        [self openResultView];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(),^{
            [self.model.bridgeDelegate trackingFaceDone];
        });
        NSLog(@"Inside process Data after process signals");
        result = processor->getPupilPixel();
        results.push_back(result);
        
        for (int i = 0; i < result.size(); i++)
            NSLog(@"Result at %f", result[i]);
        
        float stdV = calStd(result);
        float madV = calMad(result);
        
        stdValues.push_back(stdV);
        
        float currentBaseline = processor->calBaselineFromCurrentSignal();
        baselineValues.push_back(currentBaseline);
        
        [self writeSignalToFile:result];
        
        NSLog(@"STD is %f : MAD is %f", stdV, currentBaseline);
    }
}

- (void) writeSignalToFile:(std::vector<float>) data
{
    NSString *featureFile;
    NSFileHandle *fileHandle;
    

    NSString *docDir = NSSearchPathForDirectoriesInDomains(
                                                           NSDocumentDirectory,
                                                           NSUserDomainMask, YES
                                                           )[0];
    
    featureFile = [docDir
                   stringByAppendingPathComponent:
                   [NSString stringWithFormat:@"%@_%ld.csv", self.model.getCalibrationData, (long)self.iterationCounter]];

   // featureFile = [docDir stringByAppendingPathComponent:self.model.getCalibrationData];
    
    if  (![[NSFileManager defaultManager] fileExistsAtPath:featureFile]) {
        [[NSFileManager defaultManager]
         createFileAtPath:featureFile contents:nil attributes:nil];
    }
    
    fileHandle = [NSFileHandle
                  fileHandleForUpdatingAtPath:featureFile];
    
    
    for( size_t i=0; i< (size_t)data.size(); i++ )
    {
        
        NSString *text=[NSString stringWithFormat:@"%f\n",data[i]];
        
        [fileHandle writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (IBAction)showResult:(id)sender
{
    processor->closeCapture();
    
   //  NSLog(@"Calling openresultview from SHOW RESULT");
    [self openResultView];
}

-(void)openResultView
{
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
    

    
    //

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
        if (results.size() <= self.numberOfIteration)
        {
            NSLog(@"It is not fully calibrated");
            return;
        }
        
         NSArray* madValues = vector2NSArray(stdValues);
        NSLog(@"MadValues %@",madValues);
        
        NSNumber* minvalue =[madValues valueForKeyPath:@"@min.floatValue"];
        NSUInteger indexOfMinValue = [madValues indexOfObject:minvalue];
        
        if (indexOfMinValue>[self.pickedMutations count]) {
            NSLog(@"Error: min value out of bound %d", indexOfMinValue);
            return;
        }
        
        NSLog(@"Value %@, Index %d",minvalue, indexOfMinValue);
        NSLog(@"%@",self.pickedMutations[indexOfMinValue]);
        
        for( int i=0;i<=6;i++)
        {
            NSLog(@"size %@; paramiter %@",madValues[i], self.pickedMutations[i]);
            NSString *text=[NSString stringWithFormat:@"%@\n",self.pickedMutations[i]];
            
            [paramFileHandle writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        
        //    const int kThreadhold = 0;
        //    const int kPrior = 1;
        //    const int kStd = 2;
        //    const int kmWindow = 3;
        //    const int kgWindow = 4;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:[self.pickedMutations[indexOfMinValue][kThreadhold] intValue] forKey:@"s_threshold"];
        [defaults setInteger:[self.pickedMutations[indexOfMinValue][kPrior] intValue] forKey:@"s_markCost"];
        // [defaults setInteger:[self.pickedMutations[indexOfMinValue][kStd] intValue] forKey:@"s_threshold"];
        [defaults setInteger:[self.pickedMutations[indexOfMinValue][kmWindow] intValue] forKey:@"s_mbWindowSize"];
        [defaults setInteger:[self.pickedMutations[indexOfMinValue][kgWindow] intValue] forKey:@"s_windowSize"];

        
        [defaults synchronize];
                        
        // NSLog(@"Calling calibration result view controller");
        
        /*CalibrationResultViewController *distVC = [self.storyboard
                                                   instantiateViewControllerWithIdentifier:@"cbSummaryVC"];*/
        
       /* if(distVC != nil)
        {
            distVC.dataPoints = vector2NSArray(results[0]);
            distVC.dataPoints2 = vector2NSArray(results[1]);
            distVC.dataPoints3 = vector2NSArray(results[2]);
            distVC.dataPoints4 = vector2NSArray(results[3]);
            distVC.dataPoints5 = vector2NSArray(results[4]);
            
            distVC.stdValues = vector2NSArray(stdValues);
            distVC.baselineValues = vector2NSArray(baselineValues);
            
            distVC.parameters = self.parameters;
            
            [self presentViewController:distVC animated:YES completion:nil];
        }*/
    }
}

// Load the calibration video that are saved during the first iteration. There are two files
// one for each eye.

-(void)loadVideo:(NSString*) videoFileName
{
   //  NSLog(@"inside load video");
    // If either of the file is missing then quit.
    if ([leftCalbFileName  isEqual: @""] or [rightCalbFileName isEqual:@""])
    {
        NSLog(@"[Warning] %@ or %@ do not exist.", leftCalbFileName, rightCalbFileName);
        return;
    }
    
    processor->closeCapture();
    
     NSLog(@"Need to load calibration videos");
    
    VideoCapture leftCapture, rightCapture;
    
    if (!processor->loadVideo([leftCalbFileName UTF8String], leftCapture))
    {
        NSLog(@"[Warning] Left Video not found.%@", leftCalbFileName);
    }
    
    if (!processor->loadVideo([rightCalbFileName UTF8String], rightCapture))
    {
        NSLog(@"[Warning] Right Video not found.%@", rightCalbFileName);
    }
    
    processor->setVideoDevice("leftEye", leftCapture);
    processor->setVideoDevice("rightEye", rightCapture);
    
    processor->clearData();
    
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


-(void)prepareNextIteration:(NSInteger) iterNumber
{
    processor->isShouldWriteVideo = false;
    processor->isShouldDetectFace = false;
    

    
//    const int kThreadhold = 0;
//    const int kPrior = 1;
//    const int kStd = 2;
//    const int kmWindow = 3;
//    const int kgWindow = 4;


    processor->threshold_ud = [self.pickedMutations[iterNumber][kThreadhold] integerValue];
    processor->markCost = [self.pickedMutations[iterNumber][kPrior] integerValue];

    
    processor->windowSize_ud        = [self.pickedMutations[iterNumber][kmWindow] integerValue];
    processor->mbWindowSize_ud      = [self.pickedMutations[iterNumber][kgWindow] integerValue];
    
//    processor->starburstStd = [self.pickedMutations[iterNumber][kSTD] integerValue];
    
    
    
    // NSLog(@"Loadinv video ");
    // Now that we have gone through the first iteration
    [self loadVideo: @"calb"];
    
    self.isRunnningFromVideoMode = YES;
}

-(BOOL)advanceIteration
{
     NSLog(@"Inside advance iteration %ld", (long)self.iterationCounter);
    if( self.iterationCounter < self.numberOfIteration )
    {
        self.iterationCounter++;
        
        [self prepareNextIteration: self.iterationCounter];
        
        isFinished = false;
        
        NSLog(@"Inside advance iteration === %ld", (long)self.iterationCounter);
        
        
        
        return YES;
    }
    else
    {
        return NO;
    }
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
            if (self.isCalibCogMax)
            {
                isStarted = false;
                dispatch_async(dispatch_get_main_queue(),^{
                    [self processData];
                });
            }
            else
            {
                if(![self advanceIteration])
                {
                    // Finished ALL iterations
                     NSLog(@"Finished all iterations -- Calling openresultview from under advance iteration ");
                    
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
        else
        {
            if (self.isRunnningFromVideoMode)
            {
                // Replace image from camera to video
                if (![self getVideoFrame:(cv::Mat &)leftEyeImage rightEye:(cv::Mat &)rightEyeImage])
                {
                    // No more frames left in the video
                    isFinished = true;
                    dispatch_async(dispatch_get_main_queue(),^{
                        [self processData];});
                    
                    return cameraImage;
                }
                else
                {
                    // Process image from the video
                    
                    //NSLog(@"Left image channels %d", leftEyeImage.channels());
                    //NSLog(@"Right image channels %d", rightEyeImage.channels());
                    
                    //leftEyeImage.convertTo(leftEyeImage, CV_8UC3);
                    
                    // NSLog(@"Channels before converting %d", rightEyeImage.channels());
                    
//                    string ty =  type2str( leftEyeImage.type() );
//                    printf("Matrix: Left Eye %s %dx%d %d %d\n", ty.c_str(), leftEyeImage.cols, leftEyeImage.rows, leftEyeImage.type(), leftEyeImage.depth() );
//                    
//                    ty =  type2str( rightEyeImage.type() );
//                    printf("Matrix: Right Eye %s %dx%d \n", ty.c_str(), rightEyeImage.cols, rightEyeImage.rows );
                    
                    Mat leftEyeX(leftEyeImage);
                    Mat rightEyeX(rightEyeImage);
                    
                    
                    cvtColor(leftEyeX, leftEyeX, CV_BGR2GRAY);
                    cvtColor(rightEyeX, rightEyeX, CV_BGR2GRAY);
                    
                    processor->eyeFeatureExtraction(leftEyeImage, rightEyeImage, isFinished);
                    
                }
            }
            else
            {
                // Processing image from the camera.
                NSLog(@"Processing image from camera");
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
        }
         // NSLog(@"Returning camera image");
        
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
    
     NSLog(@"Output file path %@", outputFilePath);
    return outputFilePath;
}


-(void)preparePupilProcessor
{

    // Get the timestamp to save the file
    timeStampValue = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];

     NSLog(@"Time stamp %@", timeStampValue);
    
    // This is where I have to call the singleton function
    
    NSLog(@"subject ID %@", self.model.currentSubjectID);
    
    /*
    leftOutputVideoFileName = [NSString stringWithFormat:@"%@%@%@%@%@",
                               self.model.currentSubjectID,
                               @"_",
                               timeStampValue ,
                               @"_",
                               @"LeftEye"];
    rightOutputVideoFileName = [NSString stringWithFormat:@"%@%@%@%@%@",
                                self.model.currentSubjectID,
                                @"_",
                                timeStampValue ,
                                @"_",
                                @"RightEye"];
     */
    

    // Do not want to run the process until pressing start.
    isFinished = false;
    isStarted = false;

    if( !processor )
    {
//        
//        NSString* leftOutputFilePath = [self getOutputFilePath:_model.getLeftEyeName];
//        NSString* rightOutputFilePath = [self getOutputFilePath:_model.getRighEyeName];
        
//        NSLog(@"Calling writeData");
//        [self.model.currentTest writeData];
//        
//        NSLog(@"calling getCSVFilename");
//
//        NSString* csvFileName = self.model.getLeftEyeName;
//        
//        NSLog(@"csvFilename %@", csvFileName);
        
//        NSLog(@"left file name from getLeftEyeName %@", leftOutputFilePath);
//        NSLog(@"Right file name from getRightEyeName %@", rightOutputFilePath);
//

        
        // Tag on the complete path to the file name. Pass this to the new PWPupilProcessor
     //   [self.model.currentTest writeData];
                
        
        NSLog(@"tmp Left %@", self.model.getCalibrationLeftEye);
        NSLog(@"tmp right %@", self.model.getCalibrationRightEye);

        [self.model setNewCalibrationFiles];
        leftOutputVideoFileName =self.model.getCalibrationLeftEye;
        rightOutputVideoFileName =self.model.getCalibrationRightEye;
        
        // NSLog(@"Eye Distance %d", self.model.getDist);


        
        leftCalbFileName = [self getOutputFilePath:leftOutputVideoFileName];
        rightCalbFileName = [self getOutputFilePath:rightOutputVideoFileName];
        NSLog(rightCalbFileName);

         NSLog(@"Video path = %@", leftCalbFileName);
        processor = new PWPupilProcessor([leftCalbFileName UTF8String], [rightCalbFileName UTF8String]);
        processor->isShouldWriteVideo = true;

        [self loadSettingToProcessor];
    }
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
