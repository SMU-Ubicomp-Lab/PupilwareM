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


/*---------------------------------------------------------------
 Pupilware Core Header
 ---------------------------------------------------------------*/

#import "PupilwareCore/PupilwareController.hpp"
#import "PupilwareCore/Algorithm/IPupilAlgorithm.hpp"
#import "PupilwareCore/Algorithm/MDStarbustNeo.hpp"
#import "PupilwareCore/ImageProcessing/SimpleImageSegmenter.hpp"



/*---------------------------------------------------------------
 Objective C Header
 ---------------------------------------------------------------*/

@interface PWViewController2 ()

    @property (strong,nonatomic) VideoAnalgesic *videoManager;

@end


@implementation PWViewController2
{
    std::shared_ptr<pw::PupilwareController> pwCtrl;
    
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
    // Dispose of any resources that can be recreated.
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
    
    pwCtrl = pw::PupilwareController::Create();
    pwCtrl->setPupilSegmentationAlgorihtm(std::make_shared<pw::MDStarbustNeo>("StarbustNeo"));
    pwCtrl->setFaceSegmentationAlgoirhtm(std::make_shared<pw::SimpleImageSegmenter>(filePath));
    
}


- (void)initVideoManager
{
    // remove the view's background color
    self.view.backgroundColor = nil;
    
    __weak typeof(self) weakSelf = self;
    
    __block NSDictionary *opts = @{CIDetectorAccuracy: CIDetectorAccuracyLow, CIDetectorEyeBlink:@YES};
    
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:self.videoManager.ciContext
                                              options:opts];
    
    [self.videoManager setProcessBlock:^(CIImage *cameraImage){
        
        cv::Mat cvFrame = [PWViewController2 IGImage2Mat:cameraImage
                                             withContext:weakSelf.videoManager.ciContext];
        pwCtrl->processFrame(cvFrame);
        
        cv::Mat debugImg = pwCtrl->getDebugImage();
        
        cameraImage = [PWViewController2 Mat2CGImage:debugImg
                                         withContext:weakSelf.videoManager.ciContext];

        
        
//        cameraImage = [self testDrawing:cameraImage context:self.videoManager.ciContext];
//        opts = @{CIDetectorImageOrientation:@6};
//        NSArray *faceFeatures = [detector featuresInImage: cameraImage options:opts];
//        
//        for(CIFaceFeature *face in faceFeatures ){
//            NSLog(@"%@", face);
//        }
        
        return cameraImage;
        
    }];

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


-(CIImage*)testDrawing:(CIImage*) img context:(CIContext*) context{
    
    cv::Mat f = [PWViewController2 IGImage2Mat:img withContext:context];
    
    cv::circle(f, cv::Point(0,0), 300, cv::Scalar(255,0,0), -1);
    
    return [PWViewController2 Mat2CGImage:f withContext:context];
    
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////    C++ FUNCTIONS      ///////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
namespace PWViewCtrl{
    
    
}



/////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////    Helper FUNCTIONS      ///////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

+ (cv::Mat)IGImage2Mat:(CIImage*)ciFrameImage withContext:(CIContext*)context{
    
    CGRect roi = ciFrameImage.extent;
    CGImageRef imageCG = [context createCGImage:ciFrameImage fromRect:roi];
    
    // Right Eye OpenCV mat
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageCG);
    CGFloat cols = roi.size.width;
    CGFloat rows = roi.size.height;
    cv::Mat returnMat(rows, cols, CV_8UC4);
    
    // Image referecne for the right eye
    
    CGContextRef contextRef = CGBitmapContextCreate(returnMat.data,                 // Pointer to backing data
                                                    cols,                           // Width of bitmap
                                                    rows,                           // Height of bitmap
                                                    8,                              // Bits per component
                                                    returnMat.step[0],              // Bytes per row
                                                    colorSpace,                     // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault);     // Bitmap info flags

    // Do the copy
    CGContextDrawImage(contextRef,
                       CGRectMake(0, 0, cols, rows),
                       imageCG);
   
    // release intermediary buffer objects
    CGContextRelease(contextRef);
    CGImageRelease(imageCG);
    
    return returnMat;
    
}


+ (CIImage*)Mat2CGImage:(cv::Mat)opencvMat withContext:(CIContext*)context{
    
    NSData *data = [NSData dataWithBytes:opencvMat.data length:opencvMat.elemSize() * opencvMat.total()];
    
    
    CGColorSpaceRef colorSpace;
    
    if (opencvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    // setup buffering object
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // setup the copy to go from CPU to GPU
    CGImageRef imageRef = CGImageCreate(opencvMat.cols,                                     // Width
                                        opencvMat.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * opencvMat.elemSize(),                           // Bits per pixel
                                        opencvMat.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    // do the copy inside of the object instantiation for retImage
    CIImage* retImage = [[CIImage alloc]initWithCGImage:imageRef];
    
    
    // clean up
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return retImage;
    
}



@end
