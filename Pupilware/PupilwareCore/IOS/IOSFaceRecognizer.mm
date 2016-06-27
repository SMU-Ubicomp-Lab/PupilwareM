//
//  IOSFaceRecognizer.m
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/26/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

#import "IOSFaceRecognizer.h"

#import "ObjCAdapter.h"

@interface IOSFaceRecognizer()

@property(strong, nonatomic) CIDetector *detector;

@end


@implementation IOSFaceRecognizer


-(id)initWithContext:(CIContext*) context
{
    assert(context != nil);
    
    if ( self = [super init] )
    {
        __block NSDictionary *opts = @{CIDetectorAccuracy: CIDetectorAccuracyLow, CIDetectorEyeBlink:@YES};
        
        self.detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                           context:context
                                           options:opts];
    
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
    
    __block NSDictionary *opts;
    opts = @{CIDetectorImageOrientation:@6};
    
    NSArray *faceFeatures = [self.detector featuresInImage: cameraImage options:opts];
    
    // Only return the first face they found. for now.
    for(CIFaceFeature *face in faceFeatures ){
        const int kEyeBound = face.bounds.size.width *0.15;
        
        returnFaceMeta.faceRect         = [ObjCAdapter CGRect2CVRectFlip:face.bounds];
        returnFaceMeta.leftEyeClosed    = face.leftEyeClosed;
        returnFaceMeta.rightEyeClosed   = face.rightEyeClosed;
    
        
        // converted to face coordinate
        returnFaceMeta.leftEyeRect      = cv::Rect(face.leftEyePosition.y - face.bounds.origin.y - kEyeBound,
                                                   face.leftEyePosition.x - face.bounds.origin.x - kEyeBound,
                                                   kEyeBound*2,
                                                   kEyeBound*2);
        
        returnFaceMeta.rightEyeRect     = cv::Rect(face.rightEyePosition.y - face.bounds.origin.y - kEyeBound,
                                                   face.rightEyePosition.x - face.bounds.origin.x - kEyeBound,
                                                   kEyeBound*2,
                                                   kEyeBound*2);
        
        returnFaceMeta.leftEyeCenter    = cv::Point(face.leftEyePosition.y - face.bounds.origin.x - returnFaceMeta.leftEyeRect.x,
                                                    face.leftEyePosition.x - face.bounds.origin.y - returnFaceMeta.leftEyeRect.y);
        returnFaceMeta.rightEyeCenter   = cv::Point(face.rightEyePosition.y  - face.bounds.origin.y - returnFaceMeta.rightEyeRect.x,
                                                    face.rightEyePosition.x - face.bounds.origin.x - returnFaceMeta.rightEyeRect.y );
        
        break;
    }
    
    return returnFaceMeta;
}


-(void)cleanup{
    
}


@end
