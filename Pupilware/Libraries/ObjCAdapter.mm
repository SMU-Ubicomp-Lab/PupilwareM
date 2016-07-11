//
//  ObjCAdapter.m
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/26/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

#import "ObjCAdapter.h"

@implementation ObjCAdapter


/////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////    Helper FUNCTIONS      ///////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

/*
 * Source from TimZaman:
 * http://stackoverflow.com/questions/15043152/rotate-opencv-matrix-by-90-180-270-degrees
 */
+(void)Rotate90:(cv::Mat&)opencvMat withFlag:(int)rotflag{
    
    //1=CW, 2=CCW, 3=180
    if (rotflag == 1){
        transpose(opencvMat, opencvMat);
        flip(opencvMat, opencvMat,1); //transpose+flip(1)=CW
    } else if (rotflag == 2) {
        transpose(opencvMat, opencvMat);
        flip(opencvMat, opencvMat,0); //transpose+flip(0)=CCW
    } else if (rotflag ==3){
        flip(opencvMat, opencvMat,-1);    //flip(-1)=180
    } else if (rotflag != 0){ //if not 0,1,2,3:
        NSLog(@"Invalid flag");
    }
}


/*
 * Get IGImage, and convert to Opencv Mat.
 * The returning Mat is the copy of IGImage.
 */
+(cv::Mat)CIImage2Mat:(CIImage*)ciFrameImage withContext:(CIContext*)context{
    
    CGRect roi = ciFrameImage.extent;
    CGImageRef imageCG = [context createCGImage:ciFrameImage fromRect:roi];
    
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageCG);
    CGFloat cols = roi.size.width;
    CGFloat rows = roi.size.height;
    cv::Mat returnMat(rows, cols, CV_8UC4);
    
    
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
    
    
    CGContextRelease(contextRef);
    CGImageRelease(imageCG);
    
    return returnMat;
    
}


/*
 * The returning IGImage is the copy of Mat.
 */
+ (CIImage*)Mat2CIImage:(cv::Mat)opencvMat withContext:(CIContext*)context{
    
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
    CGImageRef imageRef = CGImageCreate(opencvMat.cols,                                 // Width
                                        opencvMat.rows,                                 // Height
                                        8,                                              // Bits per component
                                        8 * opencvMat.elemSize(),                       // Bits per pixel
                                        opencvMat.step[0],                              // Bytes per row
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


+(cv::Rect) CGRect2CVRect:(CGRect) cgRect{
    return cv::Rect(cgRect.origin.x,
                    cgRect.origin.y,
                    cgRect.size.width,
                    cgRect.size.height);
}

+(cv::Point) CGPoint2CVPoint:(CGPoint) cgPoint{
    return cv::Point(cgPoint.x, cgPoint.y);
}



+(NSString*)getOutputFilePath:(NSString*) outputFileName
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
    
    // NSLog(@"Output file path %@", outputFilePath);
    return outputFilePath;
}



+(NSArray*) vector2NSArray:( const std::vector<float>& )v
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
