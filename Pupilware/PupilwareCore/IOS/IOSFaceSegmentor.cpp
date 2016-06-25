//
//  IOSFaceSegmentor.cpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/25/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

#include "IOSFaceSegmentor.hpp"
#include "../preHeader.hpp"

namespace pw {
    
    
    IOSFaceSegmenter::IOSFaceSegmenter( ){
        
    }
    
    
    IOSFaceSegmenter::IOSFaceSegmenter( const IOSFaceSegmenter &other ){
        
    }
    
    
    IOSFaceSegmenter::~IOSFaceSegmenter(){
        
    }
    
    
    bool IOSFaceSegmenter::findFace(const cv::Mat grayFrame,
                                    cv::Rect &outFaceRect){
        
        REQUIRES(false, "This function has not been implemented.");
        
        return true;
        
    }
    
    
    void IOSFaceSegmenter::extractEyes(cv::Rect faceROI,
                                cv::Rect &outLeftEyeRegion,
                                       cv::Rect &outRightEyeRegion){
        
        REQUIRES(false, "This function has not been implemented.");
        
    }
    
    
    cv::Point2f IOSFaceSegmenter::fineEyeCenter(const cv::Mat grayEyeROI){
        
        REQUIRES(false, "This function has not been implemented.");
        
        return cv::Point2f();
    }
    
}