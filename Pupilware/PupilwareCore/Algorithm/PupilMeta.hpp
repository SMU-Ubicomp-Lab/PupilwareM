//
//  PupilMeta.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 5/25/16.
//  Copyright © 2016 Chatchai Wangwiwattana. All rights reserved.
//
//  Brief: It contains Pupil meta data.
//

#ifndef PupilMeta_hpp
#define PupilMeta_hpp

#include <opencv2/opencv.hpp>


namespace pw {

    class PupilMeta {

    private:
        cv::Mat             colorLeftEye;
        cv::Mat             colorRightEye;

        cv::Point           leftEyeCenter;
        cv::Point           rightEyeCenter;

        float               eyeDistancePx;

        unsigned int        frameNumber;

    public:
        PupilMeta();
        PupilMeta(const PupilMeta& other);
        PupilMeta& operator=(const PupilMeta&);
        virtual ~PupilMeta();

        unsigned int        getFrameNumber() const;
        void                setFrameNumber( unsigned int frameNumber );

        cv::Point           getLeftEyeCenter() const;
        cv::Point           getRightEyeCenter() const;
        void                setEyeCenter( cv::Point leftEyeCenter,
                                          cv::Point rightEyeCenter );

        void                setEyeImages( const cv::Mat& leftColorImage,
                                          const cv::Mat& rightColorImage );

        const cv::Mat&      getLeftEyeImage() const;
        const cv::Mat&      getRightEyeImage() const;

        const float         getEyeDistancePx() const;
        void                setEyeDistancePx( float eyeDist );

    };
}

#endif /* PupilMeta_hpp */
