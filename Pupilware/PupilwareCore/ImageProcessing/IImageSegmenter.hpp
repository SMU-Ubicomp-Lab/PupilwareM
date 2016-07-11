//
// Created by Chatchai Wangwiwattana on 5/27/16.
//

#ifndef PUPILWARE_IIMAGEPROCESSOR_HPP
#define PUPILWARE_IIMAGEPROCESSOR_HPP

#include <opencv2/opencv.hpp>

namespace pw{
    class IImageSegmenter {

    public:

        virtual bool findFace(const cv::Mat grayFrame, cv::Rect &outFaceRect) =0;

        virtual void extractEyes(cv::Rect faceROI,
                                 cv::Rect &outLeftEyeRegion,
                                 cv::Rect &outRightEyeRegion) =0;

        virtual cv::Point2f fineEyeCenter(const cv::Mat grayEyeROI)=0;

    };
}



#endif //PUPILWARE_IIMAGEPROCESSOR_HPP
