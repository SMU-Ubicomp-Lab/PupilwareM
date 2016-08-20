//
//  PWParameter.h
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 8/3/16.
//  Copyright © 2016 Chatchai Mark Wangwiwattana. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PWParameter : NSObject
//    processor->windowSize_ud        = (int)[defaults integerForKey:kWindowSize];
//    processor->mbWindowSize_ud      = (int)[defaults integerForKey:kMbWindowSize];
//    processor->eyeDistance_ud       = self.model.getDist;
//    processor->baselineStart_ud     = self.model.getBaseStart;
//    processor->baselineEnd_ud       = self.model.getBaseEnd;
//    processor->baseline             = self.model.getBaseline;
//    processor->cogHigh              = self.model.getCogHigh;

@property(nonatomic, strong) NSNumber* threshold;
@property(nonatomic, strong) NSNumber* prior;
@property(nonatomic, strong) NSNumber* sigma;
@property(nonatomic, strong) NSNumber* sbRayNumber;
@property(nonatomic, strong) NSNumber* degreeOffset;


@end
