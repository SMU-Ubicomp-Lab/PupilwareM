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


    PWFaceMeta& PWFaceMeta::operator*( double scalar ){
        
        faceRect.x      = faceRect.x * scalar;
        faceRect.y      = faceRect.y * scalar;
        faceRect.width  = faceRect.width * scalar;
        faceRect.height = faceRect.height * scalar;
        
        
        leftEyeRect.x      = leftEyeRect.x * scalar;
        leftEyeRect.y      = leftEyeRect.y * scalar;
        leftEyeRect.width  = leftEyeRect.width * scalar;
        leftEyeRect.height = leftEyeRect.height * scalar;
        
        rightEyeRect.x      = rightEyeRect.x * scalar;
        rightEyeRect.y      = rightEyeRect.y * scalar;
        rightEyeRect.width  = rightEyeRect.width * scalar;
        rightEyeRect.height = rightEyeRect.height * scalar;
        
        leftEyeCenter.x     = leftEyeCenter.x * scalar;
        leftEyeCenter.y     = leftEyeCenter.y * scalar;
        
        rightEyeCenter.x    = rightEyeCenter.x * scalar;
        rightEyeCenter.y    = rightEyeCenter.y * scalar;
        
        
        return *this;
    }
    
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