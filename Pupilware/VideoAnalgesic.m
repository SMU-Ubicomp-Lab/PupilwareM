//
//  VideoAnalgesic.m
//  FilterImage
//
//  Created by Eric Larson
//  Copyright (c) 2013 Eric Larson. All rights reserved.
//
//          Copyright © 2013 Apple Inc. All rights reserved.
//          WWDC 2013 License
//
//          NOTE: This Apple Software was supplied by Apple as part of a WWDC 2013
//          Session. Please refer to the applicable WWDC 2013 Session for further
//          information.
//
// This code has been heavily modified, per the Apple license agreement for reuse

#import "VideoAnalgesic.h"

static VideoAnalgesic *video = nil;

@interface VideoAnalgesic() <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (strong,nonatomic) NSMutableArray *activeFilters;
@property (nonatomic) AVCaptureDevicePosition devicePosition;
@end

@implementation VideoAnalgesic

static CGColorSpaceRef sDeviceRgbColorSpace = NULL;

+(VideoAnalgesic*)captureManager{
    
    // NSLog(@"Inside capture Manager");
    @synchronized(self)
	{
        // NSLog(@"Inside syncrhonied self");
        if (video == nil) {
            // NSLog(@"is video == nil ");
            video = [[VideoAnalgesic alloc]init];
            
            video->captureSessionQueue = dispatch_queue_create("capture_session_queue", NULL);
            
            video->videoIsRunning = NO;
            video.processBlock = nil;
            sDeviceRgbColorSpace = CGColorSpaceCreateDeviceRGB();
            video.devicePosition = AVCaptureDevicePositionBack;
            
            
            video.window = ([UIApplication sharedApplication].delegate).window;
            
            
            video.eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
            video.videoPreviewView = [[GLKView alloc] initWithFrame:video.window.bounds context:video.eaglContext];
            video.videoPreviewView.enableSetNeedsDisplay = NO;
            
            // because the native video image from the back camera is in UIDeviceOrientationLandscapeLeft (i.e. the home button is on the right), we need to apply a clockwise 90 degree transform so that we can draw the video preview as if we were in a landscape-oriented view; if you're using the front camera and you want to have a mirrored preview (so that the user is seeing themselves in the mirror), you need to apply an additional horizontal flip (by concatenating CGAffineTransformMakeScale(-1.0, 1.0) to the rotation transform)
            video.videoPreviewView.transform = CGAffineTransformMakeRotation(M_PI_2);
            video.videoPreviewView.frame = video.window.bounds;
            
            // we make our video preview view a subview of the window, and send it to the back; this makes FHViewController's view (and its UI elements) on top of the video preview, and also makes video preview unaffected by device rotation
            [video.window addSubview:video.videoPreviewView];
            [video.window sendSubviewToBack:video.videoPreviewView];
            
            // create the CIContext instance, note that this must be done after _videoPreviewView is properly set up
            video.ciContext = [CIContext contextWithEAGLContext:video.eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]} ];
            
            // bind the frame buffer to get the frame buffer width and height;
            // the bounds used by CIContext when drawing to a GLKView are in pixels (not points),
            // hence the need to read from the frame buffer's width and height;
            // in addition, since we will be accessing the bounds in another queue (_captureSessionQueue),
            // we want to obtain this piece of information so that we won't be
            // accessing _videoPreviewView's properties from another thread/queue
            [video.videoPreviewView bindDrawable];
            video.videoPreviewViewBounds = CGRectZero;
            
        }
    }
    
    // NSLog(@"Returnign video");
    return video;
}

+(NSNumber *)ciOrientationFromDeviceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    NSNumber *ciOrientation = @3;
    
    return ciOrientation;

    // OVERRIDEING THE DEVICE ORIENTATION
    if(interfaceOrientation == UIInterfaceOrientationPortrait){
        ciOrientation = @5;
    }
    else if(interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown){
        ciOrientation = @7;
    }
    else if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft){
        ciOrientation = @1;
    }
    else if(interfaceOrientation == UIInterfaceOrientationLandscapeRight){
        ciOrientation = @3;
    }
    else{
        //unknown orientation!
    }
    
    return ciOrientation;
}

-(void)start{
    
    _videoPreviewViewBounds.size.width = self.videoPreviewView.drawableWidth;
    _videoPreviewViewBounds.size.height = self.videoPreviewView.drawableHeight;
    
    
    // see if we have any video device
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 0)
    {
        [self _start];
        self->videoIsRunning = YES;
    }else{
        // NSLog(@"Could not start Analgesic video manager");
        self->videoIsRunning = NO;
    }
    
    if (![video.window.subviews containsObject:video.videoPreviewView]){
        [video.window addSubview:video.videoPreviewView];
        [video.window sendSubviewToBack:video.videoPreviewView];
    }
    
}

- (void)stop
{
    if (!_captureSession || !_captureSession.running)
        return;
    
    [_captureSession stopRunning];
    
    dispatch_sync(self->captureSessionQueue, ^{
        NSLog(@"waiting for capture session to end");
    });
    NSLog(@"Done!");
    
    _captureSession = nil;
    _videoDevice = nil;
    self->videoIsRunning = NO;
    
    //code modification for swift
    [video.videoPreviewView removeFromSuperview];
}

-(BOOL)isRunning{
    return self->videoIsRunning;
}

-(NSString*)preset{
    if(!_preset)
        _preset = AVCaptureSessionPresetMedium;
    
    return _preset;
}

-(void)dealloc{
    [EAGLContext setCurrentContext:self.eaglContext];
    self.processBlock = nil;
    
    [self stop];

}

- (void)_start
{
    
    if (_captureSession)
        return; // we are already running, just return
    
    dispatch_async(self->captureSessionQueue, ^(void) {
        NSError *error = nil;
        
        // get the input device and also validate the settings
        NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        
        AVCaptureDevicePosition position = self.devicePosition;
        
        _videoDevice = nil;
        for (AVCaptureDevice *device in videoDevices)
        {
            if (device.position == position) {
                _videoDevice = device;
                break;
            }
        }
        
        
        // obtain device input
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_videoDevice error:&error];
        if (!videoDeviceInput)
        {
            NSLog(@"Unable to obtain video device input, error: %@", error);
            return;
        }
        
        
        if (![_videoDevice supportsAVCaptureSessionPreset:self.preset])
        {
            NSLog(@"Capture session preset not supported by video device: %@", self.preset);
            return;
        }
        
        // CoreImage wants BGRA pixel format
        NSDictionary *outputSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInteger:kCVPixelFormatType_32BGRA]};
        
        // create the capture session
        _captureSession = [[AVCaptureSession alloc] init];
        _captureSession.sessionPreset = self.preset;
        
        // create and configure video data output
        AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        videoDataOutput.videoSettings = outputSettings;
        videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        [videoDataOutput setSampleBufferDelegate:self queue:self->captureSessionQueue];
        
        // begin configure capture session
        [_captureSession beginConfiguration];
        
        if (![_captureSession canAddOutput:videoDataOutput])
        {
            _captureSession = nil;
            return;
        }
        
        
        
        // connect the video device input and video data and still image outputs
        [_captureSession addInput:videoDeviceInput];
        [_captureSession addOutput:videoDataOutput];
        
        
//        AVCaptureDeviceFormat *bestFormat = nil;
//        AVFrameRateRange *bestFrameRateRange = nil;
//        for ( AVCaptureDeviceFormat *format in [_videoDevice formats] ) {
//            for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
//                if ( range.minFrameRate<[self.framesPerSecond floatValue] &&
//                    range.maxFrameRate>[self.framesPerSecond floatValue]) {
//                    bestFormat = format;
//                    bestFrameRateRange = range;
//                    break;
//                }
//            }
//        }
//        
//        if([_videoDevice lockForConfiguration:&error]==YES){
//            _videoDevice.activeFormat = bestFormat;
//
//            // cannot clamp FPS with bad formats
//            _videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, 1.0/[self.framesPerSecond floatValue]);
//            _videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, 1.0/[self.framesPerSecond floatValue]);
//            [_videoDevice unlockForConfiguration];
//            NSLog(@"FPS set to %.4f to %.4f, clamped to %@",bestFrameRateRange.minFrameRate,bestFrameRateRange.maxFrameRate, self.framesPerSecond);
//        }

        
        [_captureSession commitConfiguration];
        
       
        
        // then start everything
        [_captureSession startRunning];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2);
            // apply the horizontal flip
            BOOL shouldMirror = (AVCaptureDevicePositionFront == _videoDevice.position);
            if (shouldMirror)
                transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(-1.0, 1.0));
            
            _videoPreviewView.transform = transform;
            _videoPreviewView.frame = _window.bounds;
            
        });
        
    });
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // time of video capture, if you want it
    //CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    // dimensions, if you wnat them
    //CMVideoDimensions currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDesc);
    
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)imageBuffer options:nil];
    
    // run through a filter
    CIImage *filteredImage = sourceImage;
    
    if(self.processBlock)
        filteredImage=self.processBlock(sourceImage);
    
    CGRect sourceExtent = filteredImage.extent;
    
    CGFloat sourceAspect = sourceExtent.size.width / sourceExtent.size.height;
    //sourceAspect = sourceExtent.size.height / sourceExtent.size.width;
    CGFloat previewAspect = _videoPreviewViewBounds.size.width  / _videoPreviewViewBounds.size.height;
    
    // we want to maintain the aspect ratio of the screen size, so we clip the video image
    CGRect drawRect = sourceExtent;
//    if (sourceAspect > previewAspect)
//    {
//        // use full height of the video image, and center crop the width
//        drawRect.origin.x += (drawRect.size.width - drawRect.size.height * previewAspect) / 2.0;
//        drawRect.size.width = drawRect.size.height * previewAspect;
//    }
//    else
//    {
//        // use full width of the video image, and center crop the height
//        drawRect.origin.y += (drawRect.size.height - drawRect.size.width / previewAspect) / 2.0;
//        drawRect.size.height = drawRect.size.width / previewAspect;
//    }
    
    if (filteredImage)
    {
        [_videoPreviewView bindDrawable];
        
        if (_eaglContext != [EAGLContext currentContext])
            [EAGLContext setCurrentContext:_eaglContext];
        
        // clear eagl view to grey
        glClearColor(0.5, 0.5, 0.5, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        
        // set the blend mode to "source over" so that CI will use that
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        
        
        if (filteredImage)
            [_ciContext drawImage:filteredImage inRect:_videoPreviewViewBounds fromRect:drawRect];
        
        [_videoPreviewView display];
    }
    
}

-(void)setCameraPosition:(AVCaptureDevicePosition)position{
    if(position != self.devicePosition){
        self.devicePosition = position;
        if([self isRunning]){
            [self stop];
            [self start];
        }
    }
}

-(NSNumber*)framesPerSecond{
    if(!_framesPerSecond)
        _framesPerSecond = [NSNumber numberWithFloat:30.0];
    
    return _framesPerSecond;
}


#pragma mark - Block Handling
- (void)setProcessingBlock:(ProcessBlock)newProcessBlock
{
//    self.processBlock = newProcessBlock;
    _processBlock = [newProcessBlock copy];
}

#pragma mark - Notification of updates
- (void)shouldColorMatch:(BOOL)shouldColorMatch
{
    
    NSDictionary *options = shouldColorMatch ? @{kCIContextWorkingColorSpace : [NSNull null]} : nil;
    
    dispatch_async(self->captureSessionQueue, ^{
        _ciContext = [CIContext contextWithEAGLContext:_eaglContext options:options];
    });
    
    if(self.isRunning)
    {
        [self stop];
        [self _start];
    }
}



@end
