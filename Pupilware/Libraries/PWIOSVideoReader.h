//
//  PWIOSVideoReader.h
//  Pupilware
//
//  Brief: It is the warper of VideoAnalgesic.
//         It allows users to load video from a file.
//
//  Created by Chatchai Wangwiwattana on 7/11/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef cv::Mat(^CVProcessBlock)(const cv::Mat&);

@interface PWIOSVideoReader : NSObject

@property (strong,nonatomic) CVProcessBlock processBlock;
@property (strong,nonatomic) CIContext *ciContext;

-(void)setProcessBlock:(CVProcessBlock) pBlock;
-(BOOL)open:(NSString*)filename;
-(BOOL)isOpened;
-(BOOL)isRunning;
-(void)start;
-(void)stop;

@end
