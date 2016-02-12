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
#import "PWPupilProcessor.h"
#import "CalibrationResultViewController.h"
#import "PWUtilities.h"

#import "constants.h"
#import "VideoAnalgesic.h"
#import "OpenCVBridge.h"



@class commandControl;
@class VideoDisplayViewController;

using namespace cv;
using namespace pw;

static const int kFramesPerSec = 15;

@interface CalibrateViewController ()

@property (weak, nonatomic) IBOutlet UILabel *meanPupilSize;
@property (weak, nonatomic) IBOutlet UIButton *myStartButton;
@property (weak, nonatomic) IBOutlet UIView *imageView;

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


- (void)loadCamera
{
    
    // remove the view's background color
    self.view.backgroundColor = nil;
    
    NSLog(@"Inside loadCamera");
    
    __weak typeof(self) weakSelf = self;
    
    __block NSDictionary *opts = @{CIDetectorAccuracy: CIDetectorAccuracyLow, CIDetectorEyeBlink:@YES};
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:self.videoManager.ciContext options:opts];
    
    [self.videoManager setProcessBlock:^(CIImage *cameraImage){
        
        
        opts = @{CIDetectorImageOrientation:@6};
        
        NSArray *faceFeatures = [detector featuresInImage: cameraImage options:opts];
        
        
      //  CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
        
      //  transform = CGAffineTransformTranslate(transform,0, -imageView.bounds.size.height);
        for(CIFaceFeature *face in faceFeatures ){
            
            if(!face.leftEyeClosed && ! face.rightEyeClosed){
                
                cameraImage = [OpenCVBridge OpenCVTransferAndReturnFaces:face usingImage:cameraImage andContext:weakSelf.videoManager.ciContext andProcessor:(processor) andLeftEye:face.leftEyePosition andRightEye:face.rightEyePosition andIsFinished:isFinished];
            }
        }
        // TESTING NEW CODE BEGIN
        
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           self.meanPupilSize.text = [NSString stringWithFormat:@"Pupil Size: %f",
                                                      processor->getPupilSize()];
                       });
        
        if (isFinished)
        {
            
            if( self.isCalibCogMax )
            {
                NSLog(@"Inside calling calibcogmax");
                isStarted = false;
                dispatch_async(dispatch_get_main_queue(),^{
                    [self processData];
                });
            }
            else
            {
                NSLog(@"Inside before calling advance iteration");

                if(![self advanceIteration])
                {
                    NSLog(@"Inside calling advance iteration");

                    isStarted = false;
                    
                    dispatch_async(dispatch_get_main_queue(),^{
                        [self openResultView];
                    });
                }
            }
            
        }

        
//        dispatch_async(dispatch_get_main_queue(),
//                       ^{
//                           [self.graphView addX: processor->getPupilSize()
//                                              y: processor->getPupilSize()
//                                              z: processor->getPupilSize() ];
//                       });
        
        
        // TESTING NEW CODE END
        return cameraImage;
    }];
    
    //[self changeColorMatching];
}




#pragma mark - View Controller Delegate

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.iterationCounter = 0;
    self.numberOfIteration = 4;
    
    [self loadCamera];

    
    [self preparePupilProcessor];
    
    NSLog(@"Finished prep process");
    
    if(!self.isCalibCogMax)
    {
        const float kCaptureBaselineTime = 20.0f;
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
//	[self.videoCamera start];
    
    if(![self.videoManager isRunning])
        [self.videoManager start];
    
    NSLog(@"Started camera for calibrate");


}


-(void)viewWillDisappear:(BOOL)animated
{
    if([self.videoManager isRunning])
        [self.videoManager stop];
    
    [super viewWillDisappear:animated];
    
    //    [self.videoCamera stop];
    //
    //    [super viewWillDisappear:animated];
}

#pragma mark - Pupilware Processor

-(void)initParameters
{
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
    NSString *videoFileName = @"";
    NSString *videoFilePath = @"";

    videoFileName = [NSString stringWithFormat:@"%@%@%@",
                     self.participant ,
                     self.experiment,
                     self.iteration];
    
    if (self.isRunnningFromVideoMode)
    {
        
        //videoFilePath  = [self getInputVideoPath:videoFileName];
        
        videoFilePath  = [self getInputVideoPath:[NSString stringWithFormat:@"%@.mp4",videoFileName]];
        
        if ([videoFilePath  isEqual: @""])
        {
            NSLog(@"[Warning] %@ is not existed.", videoFilePath);
            
            return;
        }
    }

    
    // Do not want to run the process until pressing start.
    isFinished = false;
    isStarted = false;
    
    if( !processor )
    {
        
        NSString* outputFilePath = [self getOutputFilePath:@"calb"];

        
        processor = new PWPupilProcessor( [videoFilePath UTF8String], [outputFilePath UTF8String]);
        
        NSLog(@" Finishing newing pupilprocessor ");
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
                                [NSString stringWithFormat:@"%@.mp4", outputFileName]];
    
    NSLog(@"Output file name %s" ,[outputFilePath UTF8String]);
    
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
        std::vector<float> result = processor->getResultGraph();
        [self openResultView];
    }
    else
    {
        std::vector<float> result = processor->getPupilPixel();
        results.push_back(result);
        
        float stdV = calStd(result);
        float madV = calMad(result);
        
//        float med = median(result);
//        float pMad = (stdV+med)/med;
    
        
        stdValues.push_back(stdV);
        
        float currentBaseline = processor->calBaselineFromCurrentSignal();
        baselineValues.push_back(currentBaseline);
        
        [self writeSignalToFile:result];
        
        NSLog(@"STD is %f : MAD is %f", stdV, currentBaseline);
    }
}

- (IBAction)showResult:(id)sender
{
    [self openResultView];
}

-(void)openResultView
{
    NSLog(@"Inside open result view -- result size %ld iteration %ld", results.size(), (long) self.numberOfIteration);
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

-(void)loadVideo:(NSString*) videoFileName
{
    NSLog(@"Inside load video");
    NSString* videoFilePath  = [self getInputVideoPath:[NSString stringWithFormat:@"%@.mp4",videoFileName]];
    
    
    if ([videoFilePath  isEqual: @""])
    {
        NSLog(@"[Warning] %@ is not existed.", videoFilePath);
        
        return;
    }
    
    processor->closeCapture();
    
    if (!processor->loadVideo([videoFilePath UTF8String]))
    {
        NSLog(@"Video not found.");
    }
    
    processor->clearData();
    
}

-(void)prepareNextIteration:(NSInteger) iterNumber
{
    processor->isShouldWriteVideo = false;
    processor->isShouldDetectFace = false;
    
    processor->markCost = (int)((PWParameter*)[self.parameters objectAtIndex:iterNumber]).markCost;
    processor->threshold_ud = (int)((PWParameter*)[self.parameters objectAtIndex:iterNumber]).threadhold;

    
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
        
        return YES;
    }
    else
    {
        return NO;
    }
}

#pragma mark - OpenCV Delegate

-(BOOL)getVideoFrame:(Mat&)outFrame
{
    Mat videoFrame;
    processor->getVideoDevice() >> videoFrame;
    
    if(!videoFrame.empty())
    {
        outFrame = videoFrame;
        return YES;
    }
    
    return NO;
}

#ifdef __cplusplus
-(void)processImage:(Mat&)image
{
    
    if( !isStarted )
        return;
    

    NSLog(@"Inside processImage of calib");
    if (isFinished)
    {
        if( self.isCalibCogMax )
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
                isStarted = false;
                
                dispatch_async(dispatch_get_main_queue(),^{
                    [self openResultView];
                });
            }
        }
        
    }
    else
    {
        // Replace image from camera with video frame.
        if (self.isRunnningFromVideoMode)
        {
            if(![self getVideoFrame:image])
            {
                isFinished = true;
                dispatch_async(dispatch_get_main_queue(),^{
                    [self processData];
                });
                
                return;
            }
        }

        // Process the frame
//        if (processor->processImage(image, image))
//        {
//            
//            dispatch_async(dispatch_get_main_queue(),
//                           ^{
//                               self.meanPupilSize.text = [NSString stringWithFormat:@"Pupil Size: %f",
//                                                          processor->getPupilSize()];
//                           });
//            
//        }

    }
}

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
    NSLog(@"Inside start Experiment with iteration %ld", (long)self.iterationCounter);
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
    }
}



// NEW FUNCTION

bool faceAndEyeFeatureExtraction(cv::Mat srcImage, cv::Mat leftEyeMat, cv::Mat rightEyeMat, cv::Mat leftEyeMatColor, cv::Mat rightEyeMatColor, cv::Rect leftEyeRect, cv::Rect rightEyeRect, BOOL isFinished, cv::Mat& resultImage)
{
    
   NSLog(@"inside the face and feature extraction module");
    return true;
    
    
}
// END NEW FUNCTION TO PROCESS EYES AND COMBINE FACE TOGETHER



@end
