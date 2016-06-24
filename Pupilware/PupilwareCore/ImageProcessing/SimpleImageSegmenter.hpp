//
// Created by Chatchai Wangwiwattana on 5/27/16.
//

#ifndef PUPILWARE_BASICIMAGEPROCESSOR_HPP
#define PUPILWARE_BASICIMAGEPROCESSOR_HPP

#include "IImageSegmenter.hpp"

namespace pw{

    class SimpleImageSegmenter: public IImageSegmenter {


    private:
        cv::CascadeClassifier faceCascade;


    public:
        SimpleImageSegmenter( const std::string &fileFaceCascadePath );
        SimpleImageSegmenter( const SimpleImageSegmenter &other );
        ~SimpleImageSegmenter();

        bool            findFace(const cv::Mat grayFrame,
                                 cv::Rect &outFaceRect);

        void            extractEyes(cv::Rect faceROI,
                                    cv::Rect &outLeftEyeRegion,
                                    cv::Rect &outRightEyeRegion);

        cv::Point2f     fineEyeCenter(const cv::Mat grayEyeROI);

        void            loadFaceDetectionCascade(const std::string &filePath);

    };

}


#endif //PUPILWARE_BASICIMAGEPROCESSOR_HPP
