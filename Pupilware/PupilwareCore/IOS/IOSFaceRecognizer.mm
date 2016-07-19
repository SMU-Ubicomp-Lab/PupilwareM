//
//  IOSFaceRecognizer.m
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/26/16.
//  Copyright © 2016 SMU Ubicomp Lab All rights reserved.
//

#import "IOSFaceRecognizer.h"

#import "ObjCAdapter.h"

@interface IOSFaceRecognizer()

@property(strong, nonatomic) CIDetector *detector;
@property(strong, nonatomic) CIContext *context;

@end


@implementation IOSFaceRecognizer


-(id)initWithContext:(CIContext*) context
{
    assert(context != nil);
    
    if ( self = [super init] )
    {
        NSDictionary *opts = @{CIDetectorAccuracy: CIDetectorAccuracyLow};
        
        self.detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                           context:context
                                           options:opts];
        
        self.context = context;
    
        return self;
    }
    else
    {
        return nil;
    }
}


-(pw::PWFaceMeta)recognize:(CIImage*) cameraImage
{
    assert(self.detector != nil);
    assert(cameraImage != nil);
    
    pw::PWFaceMeta returnFaceMeta;
    
    NSDictionary *opts;
    opts = @{CIDetectorImageOrientation:@1,
             CIDetectorEyeBlink:@YES,
             CIDetectorNumberOfAngles:@YES};
    
    NSArray *faceFeatures = [self.detector featuresInImage: cameraImage options:opts];
    
    auto frameHeight = cameraImage.extent.size.height;
    
    // Only return the first face they found. for now.
    for(CIFaceFeature *face in faceFeatures ){
        
        const int kEyeBound = face.bounds.size.width * 0.15;
        
        // Get face and convert it to OpenCV coordinate (y down)
        auto faceRect = [ObjCAdapter CGRect2CVRect:face.bounds];
        faceRect.y = frameHeight - faceRect.height - faceRect.y;
    
        auto leftEyeCenter = cv::Point(fmax(face.leftEyePosition.x, kEyeBound),
                                       fmax(frameHeight-face.leftEyePosition.y, kEyeBound) );
        
        auto rightEyeCenter = cv::Point(fmax(face.rightEyePosition.x, kEyeBound),
                                        fmax(frameHeight-face.rightEyePosition.y, kEyeBound) );
        
        
        // prepare a data object, and return.
        returnFaceMeta.setFaceRect(faceRect);
        returnFaceMeta.setLeftEyeClosed(face.leftEyeClosed);
        returnFaceMeta.setRightEyeClosed(face.rightEyeClosed);
        
        
        returnFaceMeta.setLeftEyeRect(cv::Rect(leftEyeCenter.x - kEyeBound,
                                                   leftEyeCenter.y - kEyeBound,
                                                   kEyeBound*2,
                                                   kEyeBound*2));
        
        returnFaceMeta.setRightEyeRect(cv::Rect(rightEyeCenter.x - kEyeBound,
                                                   rightEyeCenter.y - kEyeBound,
                                                   kEyeBound*2,
                                                   kEyeBound*2));
        
        returnFaceMeta.setLeftEyeCenter(leftEyeCenter);
        returnFaceMeta.setRightEyeCenter(rightEyeCenter);
        
        break;
    }
    
    return returnFaceMeta;
}


-(void)cleanup{
    
}


@end
