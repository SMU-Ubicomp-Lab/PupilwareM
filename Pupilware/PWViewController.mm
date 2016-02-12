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
#import "PWPupilProcessor.h"
#import "DisplayDataViewController.h"
#import "PWUtilities.h"
#import "Pupilware-Swift.h"

#import "constants.h"
#import "VideoAnalgesic.h"
#import "OpenCVBridge.h"

@class commandControl;
@class VideoDisplayViewController;
@class DataModel;

using namespace cv;
using namespace pw;

//static const int kFramesPerSec = 15;


@interface PWViewController () <CvVideoCameraDelegate>

@property (strong,nonatomic) VideoAnalgesic *videoManager;
@property (strong,nonatomic) CIVector *center;
@property (strong,nonatomic) DataModel *model;

@property (weak, nonatomic) IBOutlet UILabel *meanPupilSize;
@property (weak, nonatomic) IBOutlet UIButton *myStartButton;
@property (weak, nonatomic) IBOutlet UILabel *experimentTitle;
 //   @property (weak, nonatomic) IBOutlet UIView *imageView;
@property (weak, nonatomic) IBOutlet APLGraphView *graphView;

- (IBAction)startExperiment:(UIButton *)sender;


@end

@implementation PWViewController
{
    PWPupilProcessor *processor;
    AVAudioPlayer *audioPlayer;
    bool isFinished;
    UIView *imageView;
    NSString *participantID;
}

float radius;

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
    
    // remove the view's background color so that our view comes through (image is displayed in back of hierarchy)
    self.view.backgroundColor = nil;
    
    
    __weak typeof(self) weakSelf = self;
    
    __block NSDictionary *opts = @{CIDetectorAccuracy: CIDetectorAccuracyLow, CIDetectorEyeBlink:@YES};
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:self.videoManager.ciContext options:opts];
    
    [self.videoManager setProcessBlock:^(CIImage *cameraImage){
        opts = @{CIDetectorImageOrientation:@6};
        
        NSArray *faceFeatures = [detector featuresInImage: cameraImage options:opts];
        
        
        //CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
        //transform = CGAffineTransformTranslate(transform,0, -imageView.bounds.size.height);
        if ([faceFeatures count] > 0){
        for(CIFaceFeature *face in faceFeatures ){
            if(!face.leftEyeClosed && !face.rightEyeClosed){
            
                cameraImage = [OpenCVBridge OpenCVTransferAndReturnFaces:face
                                                              usingImage:cameraImage
                                                              andContext:weakSelf.videoManager.ciContext
                                                            andProcessor:(processor)
                                                              andLeftEye:face.leftEyePosition
                                                             andRightEye:face.rightEyePosition
                                                           andIsFinished:isFinished];
                _model.faceInView = true;
            }
        }
        }else{
            _model.faceInView = false;
        }
        // TESTING NEW CODE BEGIN
//        
//        dispatch_async(dispatch_get_main_queue(),
//                       ^{
//                           self.meanPupilSize.text = [NSString stringWithFormat:@"Pupil Size: %f",
//                                                      processor->getPupilSize()];
//                       });
//        
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self.graphView addX: processor->getPupilSize()
                                              y: processor->getPupilSize()
                                              z: processor->getPupilSize() ];
                       });

        
        // TESTING NEW CODE END
        return cameraImage;
    }];
    
    //[self changeColorMatching];
}




-(void)changeColorMatching{
    [self.videoManager shouldColorMatch:YES];
}



#pragma mark - View Controller Delegate

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _experimentTitle.text = [NSString stringWithFormat:@"%@%@%@", self.experiment, @"  ", self.iteration];
    participantID = self.participant;
    
    [self loadCamera];
    [self preparePupilProcessor];
    /*DataModel **/
    _model = [DataModel sharedInstance];
}


- (void)dealloc
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

-(void)preparePupilProcessor
{
    NSString *videoFileName = @"";
    NSString *videoFilePath = @"";

    videoFileName = [NSString stringWithFormat:@"%@%@%@",
                     self.participant ,
                     self.experiment,
                     self.iteration];

    self.graphView.hidden = false;
    if (!imageView)
    {
        imageView = [[UIView alloc] init];
        [self.view addSubview:imageView];
    }
    [imageView setFrame:CGRectMake(13, 77, 294, 317)];
    
    
    
    if (self.isRunnningFromVideoMode)
    {
        
        videoFilePath  = [self getInputVideoPath:videoFileName];
        
        if ([videoFilePath  isEqual: @""])
        {
            NSLog(@"[Warning] %@ is not existed.", videoFilePath);
            
            return;
        }

        _myStartButton.hidden = true;
        
        // Start run the processor immediately.
        isFinished = false;
    }
    else
    {
        // Do not want to run the process until pressing start.
        isFinished = true;
    }
    
    
    if( !processor )
    {
        
        NSString* outputFilePath = [self getOutputFilePath:videoFileName];
        
        processor = new PWPupilProcessor([videoFilePath UTF8String], [outputFilePath UTF8String]);
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
                                [NSString stringWithFormat:@"%@_out.mp4", outputFileName]];
    
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


- (void) writeSignalToFile
{
    NSString *featureFile;
    NSFileHandle *fileHandle;
    
    NSString *docDir = NSSearchPathForDirectoriesInDomains(
                                                           NSDocumentDirectory,
                                                           NSUserDomainMask, YES
                                                           )[0];
    featureFile = [docDir
                            stringByAppendingPathComponent:
                            [NSString stringWithFormat:@"%@%@%@.csv", self.participant , self.experiment, self.iteration]];

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
    
    
    std::vector<float> result = processor->getResultGraph();
    
    [self writeSignalToFile];
    
    DisplayDataViewController *distVC = [self.storyboard
                                         instantiateViewControllerWithIdentifier:@"summaryVC"];
    
    if(distVC != nil)
    {
        distVC.dataPoints = vector2NSArray(result);
        distVC.cogLevel = @(processor->getCognitiveLevel());
        
        [self presentViewController:distVC animated:YES completion:nil];
    }
    
}


#pragma mark - UI Event Handlers

- (IBAction)ShowData:(UIButton *)sender
{
    isFinished = true;
    

    [self processData];
}


- (IBAction)startExperiment:(UIButton *)sender {
    
//    if ((!self.baseline))
//    {
//        NSString *audioFile;
//        audioFile = [NSString stringWithFormat:@"%@%@%@", self.experiment, @"_", self.iteration];
//
//        NSString *soundFile=[[NSBundle mainBundle] pathForResource:audioFile ofType:@"mp3"];
//
//        NSError *error = nil;
//
//        audioPlayer = [[ AVAudioPlayer alloc] initWithContentsOfURL:[ NSURL fileURLWithPath: soundFile] error:&error];
//        
//        if (error)
//        {
//            NSLog(@"Error in audioPlayer: %@",[error localizedDescription]);
//        }
//        else
//        {
//            [audioPlayer play];
//
//        }
//    }
    
    isFinished = false;

}



@end
