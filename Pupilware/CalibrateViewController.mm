//
//  PWViewController.m
//  Pupilware
//
//  Created by Mark Wang on 4/1/14.
//  Copyright (c) 2014 SMU. All rights reserved.
//

#import "CalibrateViewController.h"
#import "APLGraphView.h"
#import <opencv2/highgui/cap_ios.h>
#import "opencv2/highgui/ios.h"
#import "PWPupilProcessor.h"
#import "CalibrationResultViewController.h"
#import "PWUtilities.h"
#import "MyCvVideoCamera.h"

#import "constants.h"
#import "VideoAnalgesic.h"
#import "OpenCVBridge.h"



@class commandControl;
@class VideoDisplayViewController;

using namespace cv;
using namespace pw;

NSString *leftOutputVideoFileName = @"";
NSString *rightOutputVideoFileName = @"";

NSString *leftCalbFileName = @"";
NSString *rightCalbFileName = @"";

static const int kFramesPerSec = 15;

@interface CalibrateViewController () <CvVideoCameraDelegate>

@property (weak, nonatomic) IBOutlet UILabel *meanPupilSize;
@property (weak, nonatomic) IBOutlet UIButton *myStartButton;
@property (weak, nonatomic) IBOutlet UIView *imageView; // Changed this from UIView to UIImageView
@property (strong, nonatomic) MyCvVideoCamera *videoCamera;

@property (strong, nonatomic) NSMutableArray* parameters;

@property (nonatomic) NSInteger iterationCounter;

    - (IBAction)startExperiment:(UIButton *)sender;

@property (strong,nonatomic) VideoAnalgesic *videoManager;


@end

@implementation CalibrateViewController
{
    PWPupilProcessor *processor;
    std::vector<std::vector<float>> results;
    std::vector<float> stdValues;
    std::vector<float> baselineValues;
    
    bool isStarted;
    bool isFinished;
}

-(VideoAnalgesic*)videoManager{
    if(!_videoManager){
        _videoManager = [VideoAnalgesic captureManager];
        _videoManager.preset = AVCaptureSessionPresetMedium;
        [_videoManager setCameraPosition:AVCaptureDevicePositionFront];
    }
    return _videoManager;
    
}

string type2str(int type) {
    string r;
    
    uchar depth = type & CV_MAT_DEPTH_MASK;
    uchar chans = 1 + (type >> CV_CN_SHIFT);
    
    switch ( depth ) {
        case CV_8U:  r = "8U"; break;
        case CV_8S:  r = "8S"; break;
        case CV_16U: r = "16U"; break;
        case CV_16S: r = "16S"; break;
        case CV_32S: r = "32S"; break;
        case CV_32F: r = "32F"; break;
        case CV_64F: r = "64F"; break;
        default:     r = "User"; break;
    }
    
    r += "C";
    r += (chans+'0');
    
    return r;
}



- (void)loadCamera
{
//    if (!isStarted)
//        return;
    
    // remove the view's background color
    self.view.backgroundColor = nil;
    
    NSLog(@"Calibrate view: Inside loadCamera");
    
    __weak typeof(self) weakSelf = self;
    
    __block NSDictionary *opts = @{CIDetectorAccuracy: CIDetectorAccuracyLow, CIDetectorEyeBlink:@YES};
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:self.videoManager.ciContext options:opts];
    
    
    // Replace the following code with the code from the old process Image of reading the video file. Also add the face and feature extraction function. This should be simpler
    
    Mat leftEyeImage, rightEyeImage, tmpLeftEyeImage, tmpRightEyeImage;
    
    // First Iteration... still capture from camera.
    [self.videoManager setProcessBlock:^(CIImage *cameraImage){
        
        
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
                           NSLog(@"Calling openresultview from under advance iteration ");

                           
                           isStarted = false;
                           dispatch_async(dispatch_get_main_queue(),^{
                               [self openResultView];
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
                          
                          NSLog(@"Channels before converting %d", rightEyeImage.channels());
                          
                          string ty =  type2str( leftEyeImage.type() );
                          printf("Matrix: Left Eye %s %dx%d %d %d\n", ty.c_str(), leftEyeImage.cols, leftEyeImage.rows, leftEyeImage.type(), leftEyeImage.depth() );
                          
                          ty =  type2str( rightEyeImage.type() );
                          printf("Matrix: Right Eye %s %dx%d \n", ty.c_str(), rightEyeImage.cols, rightEyeImage.rows );

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
        
                   NSLog(@"REPEATING");
                   
                   dispatch_async(dispatch_get_main_queue(),
                           ^{
                               self.meanPupilSize.text = [NSString stringWithFormat:@"Pupil Size: %f",
                                                          processor->getPupilSize()];
                           });
                  }
                NSLog(@"Returning camera image");

                return cameraImage;
        
           }];
}


                                


-(CvVideoCamera *)videoCamera
{
    if(!_videoCamera)
    {
        _videoCamera= [[MyCvVideoCamera alloc ] initWithParentView:self.imageView];
        _videoCamera.delegate = self;
        _videoCamera.defaultAVCaptureDevicePosition=AVCaptureDevicePositionFront;
        _videoCamera.defaultAVCaptureSessionPreset=AVCaptureSessionPresetHigh;
        _videoCamera.defaultAVCaptureVideoOrientation=AVCaptureVideoOrientationPortrait;
        _videoCamera.defaultFPS = kFramesPerSec;
        _videoCamera.grayscaleMode = NO;
        
        
    }
    return  _videoCamera;
}

#pragma mark - View Controller Delegate

- (void)viewDidLoad
{
    [super viewDidLoad];
   // NSLog(@"Calibrate view controller view did load");

    self.iterationCounter = 0;
    self.numberOfIteration = 4;
    
    [self preparePupilProcessor];
    
    //[self loadCamera];
    
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
}


-(void)viewWillAppear:(BOOL)animated
{
    [self initParameters];
}

- (void)dealloc
{
    if( processor )
    {
        delete processor;
        processor = nullptr;
    }
}


-(void)didReceiveMemoryWarning
{
    if( processor )
    {
        delete processor;
        processor = nullptr;
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

#pragma mark - Pupilware Processor

-(void)initParameters
{
    // NSLog(@"Inside calibrateview init parameters");

    NSArray *markCosts = @[@1, @3];
    NSArray *threadholds = @[@25, @35];
    
    self.parameters = [[NSMutableArray alloc] init];
    
    
    // Add the default parameter
    PWParameter* p = [[PWParameter alloc] init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    p.markCost = (int)[defaults integerForKey:kMarkCost];
    p.threadhold = (int)[defaults integerForKey:kThreshold];
    [self.parameters addObject:p];
    
    
    for (int i=0; i<markCosts.count; i++)
    {
        for (int j=0; j<threadholds.count; j++)
        {
            PWParameter* p = [[PWParameter alloc] init];
            
            p.markCost = [[markCosts objectAtIndex:i] intValue];
            p.threadhold = [[threadholds objectAtIndex:j] intValue];
            
            [self.parameters addObject:p];
            
        }
    }
}

-(void)preparePupilProcessor
{

    // Get the timestamp to save the file
    NSString * timeStampValue = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
    
    // NSLog(@"Time stamp %@", timeStampValue);
    
    leftOutputVideoFileName = [NSString stringWithFormat:@"%@%@%@",
                         timeStampValue ,
                         @"_",
                         @"LeftEye"];
    rightOutputVideoFileName = [NSString stringWithFormat:@"%@%@%@",
                          timeStampValue ,
                          @"_",
                          @"RightEye"];
    

    // Do not want to run the process until pressing start.
    isFinished = false;
    isStarted = false;
    
    if( !processor )
    {
        
        leftCalbFileName = [self getOutputFilePath:leftOutputVideoFileName];
        rightCalbFileName = [self getOutputFilePath:rightOutputVideoFileName];

        NSLog(@"VIdeo path = %@", leftCalbFileName);
        processor = new PWPupilProcessor([leftCalbFileName UTF8String], [rightCalbFileName UTF8String]);
        processor->isShouldWriteVideo = true;

        [self loadSettingToProcessor];
    }
    
}


-(NSString*)getInputVideoPath:(NSString*) inputVideoFileName
{
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                            NSUserDomainMask,
                                                            YES)
                        objectAtIndex:0];
    
    NSString *inputFilePath = [docDir stringByAppendingPathComponent:inputVideoFileName];
    
    return inputFilePath;
}


-(NSString*)getOutputFilePath:(NSString*) outputFileName
{
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                            NSUserDomainMask,
                                                            YES)
                        objectAtIndex:0];
    
    NSString *outputFilePath = [docDir stringByAppendingPathComponent:
                                [NSString stringWithFormat:@"%@_Calib.mp4", outputFileName]];
    
    // NSLog(@"Output file name %s" ,[outputFilePath UTF8String]);
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // OpenCV.open does not work with file that is already existed.
    // So, if there is, it needs to be deleted.
    NSError *error;
    [fm removeItemAtPath:outputFilePath error:&error];
    
    return outputFilePath;
}


-(void)loadSettingToProcessor
{

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    processor->eyeDistance_ud       = [defaults floatForKey:kEyeDistance];
    processor->windowSize_ud        = (int)[defaults integerForKey:kWindowSize];
    processor->mbWindowSize_ud      = (int)[defaults integerForKey:kMbWindowSize];
    processor->baselineStart_ud     = (int)[defaults integerForKey:kBaselineStart];
    processor->baselineEnd_ud       = (int)[defaults integerForKey:kBaselineEnd];
    processor->threshold_ud         = (int)[defaults integerForKey:kThreshold];
    processor->markCost             = (int)[defaults integerForKey:kMarkCost];
    processor->baseline             = [defaults floatForKey:kBaseline];
    processor->cogHigh              = [defaults floatForKey:kCogHighSize];
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
                            [NSString stringWithFormat:@"%@%@%@_%ld.csv", self.participant , self.experiment, self.iteration, (long)self.iterationCounter]];

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


-(void)processData
{

    processor->process_signal();
    
    if(self.isCalibCogMax)
    {
        NSLog(@"Calling openresultview from process Data isCalibCogMax");

        std::vector<float> result = processor->getResultGraph();
        [self openResultView];
    }
    else
    {
        std::vector<float> result = processor->getPupilPixel();
        results.push_back(result);
        
        float stdV = calStd(result);
        float madV = calMad(result);
        
        stdValues.push_back(stdV);
        
        float currentBaseline = processor->calBaselineFromCurrentSignal();
        baselineValues.push_back(currentBaseline);
        
        [self writeSignalToFile:result];
        
        NSLog(@"STD is %f : MAD is %f", stdV, currentBaseline);
    }
}

- (IBAction)showResult:(id)sender
{
    processor->closeCapture();

    NSLog(@"Calling openresultview from SHOW RESULT");
    [self openResultView];
}

-(void)openResultView
{
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
    
        NSLog(@"Calling calibration result view controller");
        
        CalibrationResultViewController *distVC = [self.storyboard
                                             instantiateViewControllerWithIdentifier:@"cbSummaryVC"];
        
        if(distVC != nil)
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
        }
    }
}

// Load the calibration video that are saved during the first iteration. There are two files
// one for each eye.

-(void)loadVideo:(NSString*) videoFileName
{

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

-(void)prepareNextIteration:(NSInteger) iterNumber
{
    processor->isShouldWriteVideo = false;
    processor->isShouldDetectFace = false;
    
    processor->markCost = (int)((PWParameter*)[self.parameters objectAtIndex:iterNumber]).markCost;
    processor->threshold_ud = (int)((PWParameter*)[self.parameters objectAtIndex:iterNumber]).threadhold;

    // Now that we have gone through the first iteration
    [self loadVideo: @"calb"];
    
    self.isRunnningFromVideoMode = YES;
}

-(BOOL)advanceIteration
{
    // NSLog(@"Inside advance iteration %ld", (long)self.iterationCounter);
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

#pragma mark - OpenCV Delegate

#ifdef __cplusplus

-(void)processImage:(Mat&)image
{
    NSLog(@"Inside processImage of calib");
    
}

#endif

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
        NSLog(@"Returning Yes");
        return YES;
    }
    NSLog(@"Returning NO");
    return NO;
}

#ifdef __cplusplus
#endif

-(void)createLoadingView
{
    assert(NO); //TODO it is not done yet.
    
    UIView* view = [[UIView alloc] initWithFrame:self.view.bounds];
    view.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
    [self.view addSubview:view];
}

// Timer event!
-(void)finishTheIteration
{
    //[self createLoadingView];
    isFinished = true;

    [self processData];
}

#pragma mark - UI Event Handlers

- (IBAction)startExperiment:(UIButton *)sender
{
    if (isStarted)
    {
        [self finishTheIteration];
    }
    else
    {
        isFinished = false;
        isStarted = true;
        
        self.iterationCounter = 0;
        
        [self.myStartButton setEnabled:NO];
        [self.myStartButton setTitle:@"Processing" forState:UIControlStateNormal];
        
        [UIView animateWithDuration:2.0 animations:^{
            self.myStartButton.backgroundColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.5];
        }];
        [self loadCamera];
    }
}

@end
