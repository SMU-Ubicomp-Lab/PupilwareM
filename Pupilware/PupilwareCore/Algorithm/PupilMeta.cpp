//
//  PupilMeta.cpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 5/25/16.
//  Copyright © 2016 Chatchai Wangwiwattana. All rights reserved.
//

#include "PupilMeta.hpp"

namespace pw {

    PupilMeta::PupilMeta(){}

    PupilMeta::PupilMeta(const PupilMeta& other){
        this->colorLeftEye = other.colorLeftEye.clone();
        this->colorRightEye = other.colorRightEye.clone();

        this->leftEyeCenter = other.leftEyeCenter;
        this->rightEyeCenter = other.rightEyeCenter;

        this->frameNumber = other.frameNumber;
    }

    PupilMeta& PupilMeta::operator=(const PupilMeta& other){
        PupilMeta* newObj = new PupilMeta();
        newObj->colorLeftEye = other.colorLeftEye.clone();
        newObj->colorRightEye = other.colorRightEye.clone();

        newObj->leftEyeCenter = other.leftEyeCenter;
        newObj->rightEyeCenter = other.rightEyeCenter;

        newObj->frameNumber = other.frameNumber;

        return *newObj;
    }

    PupilMeta::~PupilMeta(){}


    cv::Point PupilMeta::getLeftEyeCenter() const {
        return leftEyeCenter;
    }


    cv::Point PupilMeta::getRightEyeCenter() const {
        return rightEyeCenter;
    }


    void PupilMeta::setEyeCenter(cv::Point leftEyeCenter,
                                 cv::Point rightEyeCenter) {
        this->leftEyeCenter = leftEyeCenter;
        this->rightEyeCenter = rightEyeCenter;
    }

    unsigned int PupilMeta::getFrameNumber() const{
        return frameNumber;
    }


    void PupilMeta::setFrameNumber(unsigned int frameNumber){
        this->frameNumber = frameNumber;
    }


    void PupilMeta::setEyeImages( const cv::Mat& leftColorImage,
                              const cv::Mat& rightColorImage){

        colorLeftEye = leftColorImage.clone();
        colorRightEye = rightColorImage.clone();
    }


    const cv::Mat& PupilMeta::getLeftEyeImage() const{
        return colorLeftEye;
    }


    const cv::Mat& PupilMeta::getRightEyeImage() const{
        return colorRightEye;
    }

    const float         PupilMeta::getEyeDistancePx() const{

        return eyeDistancePx;
    }


    void                PupilMeta::setEyeDistancePx( float eyeDist ){

        eyeDistancePx = eyeDist;

    }

}