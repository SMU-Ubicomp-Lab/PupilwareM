//
//  PWViewController.m
//  Pupilware
//
//  Created by Mark Wang on 4/1/14.
//  Copyright (c) 2014 SMU. All rights reserved.
//

#import "PWViewController.h"
#import "APLGraphView.h"
#import <opencv2/highgui/cap_ios.h>
#import "PWPupilProcessor.hpp"
#import "DisplayDataViewController.h"
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
using namespace pw;

static const int kFramesPerSec = 15;


@interface PWViewController () <CvVideoCameraDelegate>

@property (strong,nonatomic) VideoAnalgesic *videoManager;
@property (strong,nonatomic) CIVector *center;
@property (strong,nonatomic) DataModel *model;

    @property (weak, nonatomic) IBOutlet UILabel *meanPupilSize;
    @property (weak, nonatomic) IBOutlet UIButton *myStartButton;
    @property (weak, nonatomic) IBOutlet UILabel *experimentTitle;
 //   @property (weak, nonatomic) IBOutlet UIView *imageView;

    @property (weak, nonatomic) IBOutlet APLGraphView *graphView;
    @property (weak, nonatomic) IBOutlet UIWebView *gameView;

    @property(strong, nonatomic) MyCvVideoCamera *videoCamera;


    - (IBAction)startExperiment:(UIButton *)sender;


@end

@implementation PWViewController
{
    PWPupilProcessor *processor;
    AVAudioPlayer *audioPlayer;
    bool isFinished;
    //UIView *imageView;
    NSString *participantID;
    NSString * timeStampValue;
    NSString * csvFileName;


}

float radius;

-(VideoAnalgesic*)videoManager{
    if(!_videoManager){
        // NSLog(@"Settign video manager");
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
    
    __weak typeof(self) weakSelf = self;
    
    __block NSDictionary *opts = @{CIDetectorAccuracy: CIDetectorAccuracyLow, CIDetectorEyeBlink:@YES};
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:self.videoManager.ciContext options:opts];
    
    // Following block of code gets the image from the camera and calls OpenCVBridge. If either of the eyes
    // are closed, then skip the frame.
    
    [self.videoManager setProcessBlock:^(CIImage *cameraImage){
        

        opts = @{CIDetectorImageOrientation:@6};
        
        NSArray *faceFeatures = [detector featuresInImage: cameraImage options:opts];
        if ([faceFeatures count] > 0){
            for(CIFaceFeature *face in faceFeatures ){

                if(!face.leftEyeClosed && ! face.rightEyeClosed){
            
                    cameraImage = [OpenCVBridge OpenCVTransferAndReturnFaces:face usingImage:cameraImage andContext:weakSelf.videoManager.ciContext andProcessor:(processor) andLeftEye:face.leftEyePosition andRightEye:face.rightEyePosition andIsFinished:isFinished];
                }
            }
            
            self.model.faceInView = true;
        }else{
            self.model.faceInView = false;
        }
        
        // Displays the pupil size on the screen
        
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           self.meanPupilSize.text = [NSString stringWithFormat:@"Pupil Size: %f",
                                                      processor->getPupilSize()];
                       });
        
        // Draws the graph on the screen

        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self.graphView addX: processor->getPupilSize()
                                              y: processor->getPupilSize()
                                              z: processor->getPupilSize() ];
                       });

        
        return cameraImage;
    }];
}

-(CvVideoCamera *)videoCamera
{
//    if(!_videoCamera)
//    {
//        _videoCamera= [[MyCvVideoCamera alloc ] initWithParentView:imageView];
//        _videoCamera.delegate = self;
//        _videoCamera.defaultAVCaptureDevicePosition=AVCaptureDevicePositionFront;
//        _videoCamera.defaultAVCaptureSessionPreset=AVCaptureSessionPresetHigh;
//        _videoCamera.defaultAVCaptureVideoOrientation=AVCaptureVideoOrientationPortrait;
//        _videoCamera.defaultFPS = kFramesPerSec;
//        _videoCamera.grayscaleMode = NO;
//        
//    }
    
    return  _videoCamera;
}


-(void)changeColorMatching{
    [self.videoManager shouldColorMatch:YES];
}

-(DataModel*)model{
    if(!_model){
        _model = [DataModel sharedInstance];
    }
    return _model;
}

#pragma mark - View Controller Delegate

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    isFinished = false;
    
   //  NSLog(@"Inside PWViewController");
    
    _experimentTitle.text = [NSString stringWithFormat:@"%@%@%@", self.experiment, @"  ", self.iteration];
    
    participantID = self.participant;
    
    [self loadCamera];

    [self preparePupilProcessor];
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
    
    // Added following two lines to close the capture files and process data
    //
    processor->closeCapture();
    
    [self processData];
    
    [super viewWillDisappear:animated];
}

#pragma mark - Pupilware Processor

-(void)preparePupilProcessor
{
    // Define the file name for both left and right eyes. Instead of using the participant number
    // and ID, we will use timestamp and designate left and right eye
    
    timeStampValue = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];

    // Do not want to run the process until pressing start.
    // isFinished = true; // NOT SURE IF THIS IS WHAT I WANT TO DO.
    
    if( !processor )
    {
        // Tag on the complete path to the file name. Pass this to the new PWPupilProcessor
        [self.model writeMetaData];
        NSString* leftOutputFilePath = [self getOutputFilePath:self.model.getLeftEyeName];
        NSString* rightOutputFilePath = [self getOutputFilePath:self.model.getRighEyeName];
        csvFileName = self.model.getCSVFileName;
        
        processor = new PWPupilProcessor([leftOutputFilePath UTF8String], [rightOutputFilePath UTF8String]);
        
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
    
    NSString *inputFilePath = [docDir stringByAppendingPathComponent:
                               [NSString stringWithFormat:@"%@.mp4",inputVideoFileName]];
    
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
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // OpenCV.open does not work with file that is already existed.
    // So, if there is, it needs to be deleted.
    NSError *error;
    [fm removeItemAtPath:outputFilePath error:&error];
    
    // NSLog(@"Output file path %@", outputFilePath);
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
    
    NSLog(@"Default values in PWViewCOntroller");
    NSLog(@"Eye Distance %f, window size %d, mbWindowsize %d, baseline start %d, basline end %d, threshold %d, mark cost %d, Baseline %f, coghigh %f", processor->eyeDistance_ud, processor->windowSize_ud, processor->mbWindowSize_ud, processor->baselineStart_ud, processor->baselineEnd_ud, processor->threshold_ud, processor->markCost, processor->baseline, processor->cogHigh);
}


- (void) writeSignalToFile
{
    NSString *featureFile;
    NSFileHandle *fileHandle;
    
    
    NSString *docDir = NSSearchPathForDirectoriesInDomains(
                                                           NSDocumentDirectory,
                                                           NSUserDomainMask, YES
                                                           )[0];
//    featureFile = [docDir
//                            stringByAppendingPathComponent:
//                            [NSString stringWithFormat:@"%@_%@.csv", timeStampValue,self.iteration]];
    
    featureFile = [docDir
                   stringByAppendingPathComponent:
                   [NSString stringWithFormat:@"%@.csv", csvFileName]];


    if  (![[NSFileManager defaultManager] fileExistsAtPath:featureFile]) {
        [[NSFileManager defaultManager]
         createFileAtPath:featureFile contents:nil attributes:nil];
    }

    fileHandle = [NSFileHandle
                                fileHandleForUpdatingAtPath:featureFile];


    std::vector<float> result = processor->getResultGraph();
    
    for( size_t i=0; i< (size_t)result.size(); i++ )
    {

        NSString *text=[NSString stringWithFormat:@"%f\n",result[i]];

        [fileHandle writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
    }
}


-(void)processData
{
  
    processor->process_signal();
    
    NSLog(@"Inside process Data");
    
    // std::vector<float> result = processor->getResultGraph();
    
    [self writeSignalToFile];
//    
//    DisplayDataViewController *distVC = [self.storyboard
//                                         instantiateViewControllerWithIdentifier:@"summaryVC"];
//    
//    if(distVC != nil)
//    {
//        distVC.dataPoints = vector2NSArray(result);
//        distVC.cogLevel = @(processor->getCognitiveLevel());
//        
//        [self presentViewController:distVC animated:YES completion:nil];
//    }
//    NSLog(@"Finished process Data");
//    
}

#pragma mark - OpenCV Delegate

#ifdef __cplusplus

-(void)processImage:(Mat&)image
{
    NSLog(@"Inside processImage of calib");

}

#endif

#pragma mark - UI Event Handlers

- (IBAction)ShowData:(UIButton *)sender
{
    isFinished = true;
    
    // (@"INSIDE THE SHOWDATA");
    processor->closeCapture();
    
    [self processData];
}


- (IBAction)startExperiment:(UIButton *)sender {
    
    // NSLog(@"Inside start experiment ");
    if ((!self.baseline) and (!self.game))
    {
        // NSLog(@"Not a baseline and game ");

        NSString *audioFile;
        audioFile = [NSString stringWithFormat:@"%@%@%@", self.experiment, @"_", self.iteration];

        NSString *soundFile=[[NSBundle mainBundle] pathForResource:audioFile ofType:@"mp3"];

        NSError *error = nil;

        audioPlayer = [[ AVAudioPlayer alloc] initWithContentsOfURL:[ NSURL fileURLWithPath: soundFile] error:&error];
        
        if (error)
        {
            NSLog(@"Error in audioPlayer: %@",[error localizedDescription]);
        }
        else
        {
            [audioPlayer play];

        }
    }
    
    
    
    isFinished = false;

}



@end
