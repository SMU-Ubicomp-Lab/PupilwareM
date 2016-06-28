//
//  PWFaceMeta.cpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 6/26/16.
//  Copyright © 2016 SMU Ubicomp Lab All rights reserved.
//

#include "PWFaceMeta.hpp"

namespace pw {
    
    PWFaceMeta::PWFaceMeta():
    leftEyeClosed(false)
    , rightEyeClosed(0)
    , eyeDistancePx(0)
    , frameNumber(0){}

    
    PWFaceMeta::~PWFaceMeta(){}
    
    
    cv::Point PWFaceMeta::getLeftEyeCenter() const {
        return leftEyeCenter;
    }
    
    
    cv::Point PWFaceMeta::getRightEyeCenter() const {
        return rightEyeCenter;
    }
    
    
    void PWFaceMeta::setLeftEyeCenter(cv::Point leftEyeCenter){
        this->leftEyeCenter = leftEyeCenter;
    }
    
    void PWFaceMeta::setRightEyeCenter(cv::Point rightEyeCenter) {
        this->rightEyeCenter = rightEyeCenter;
    }
    
    unsigned int PWFaceMeta::getFrameNumber() const{
        return frameNumber;
    }
    
    
    void PWFaceMeta::setFrameNumber(unsigned int frameNumber){
        this->frameNumber = frameNumber;
    }
    

    const float PWFaceMeta::getEyeDistancePx() const{
        
        return eyeDistancePx;
    }
    
    
    void PWFaceMeta::setEyeDistancePx( float eyeDist ){
        
        eyeDistancePx = eyeDist;
        
    }
    
    const cv::Rect& PWFaceMeta::getLeftEyeRect() const{
        return leftEyeRect;
    }
    
    
    void PWFaceMeta::setLeftEyeRect( const cv::Rect& eyeRect ){
        
        this->leftEyeRect = eyeRect;
    }
    
    const cv::Rect& PWFaceMeta::getRightEyeRect() const{
        
        return rightEyeRect;
        
    }
    
    
    void PWFaceMeta::setRightEyeRect( const cv::Rect& eyeRect ){
        this->rightEyeRect = eyeRect;
    }
    
    
    const cv::Rect& PWFaceMeta::getFaceRect() const{
        
        return faceRect;
    }
    
    
    void PWFaceMeta::setFaceRect( const cv::Rect& faceRect ){
        this->faceRect = faceRect;
    }
    
    
    
    bool PWFaceMeta::isLeftEyeClosed() const{
        return leftEyeClosed;
        
    }
    
    
    bool PWFaceMeta::isRightEyeClosed() const{
        return rightEyeClosed;
        
    }
    
    void PWFaceMeta::setLeftEyeClosed( bool closed ){
        leftEyeClosed = closed;
    }

    void PWFaceMeta::setRightEyeClosed( bool closed ){
        rightEyeClosed = closed;
    }
    
}