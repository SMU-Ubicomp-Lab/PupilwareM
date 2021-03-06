//
//  IOSFaceRecognizer.h
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/26/16.
//  Copyright © 2016 SMU Ubicomp Lab All rights reserved.
//

#import <Foundation/Foundation.h>

#include "../Algorithm/PWFaceMeta.hpp"

@interface IOSFaceRecognizer : NSObject

-(id)initWithContext:(CIContext*) context;
-(pw::PWFaceMeta)recognize:(CIImage*) cameraImage;

@end
