//
//  mdStarbust.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 5/25/16.
//  Copyright © 2016 Chatchai Wangwiwattana. All rights reserved.
//

#ifndef PixelCount_hpp
#define PixelCount_hpp

#include "IPupilAlgorithm.hpp"
#include "opencv2/video/tracking.hpp"

namespace pw {

    class PixelCount : public IPupilAlgorithm {
    
    public:
        PixelCount( const std::string& name);
        PixelCount( const PixelCount& other)=default;
        PixelCount( PixelCount&& other)=default;
        PixelCount& operator=( const PixelCount& other)=default;
        PixelCount& operator=( PixelCount&& other)=default;
        virtual ~PixelCount();
        
        virtual void init() override final;
        virtual PWPupilSize process( const cv::Mat& src, const PWFaceMeta &meta ) override final;
        virtual void exit() override final;
        
    private:
        int th;

        // Just a window name for debuging
        std::shared_ptr<CVWindow> window;

        // Debug Image
        cv::Mat debugImage;

        cv::KalmanFilter KF;
        cv::Mat measurement = cv::Mat::zeros(1, 1, CV_32F);
        cv::Mat state= cv::Mat::zeros(2, 1, CV_32F); /* (phi, delta_phi) */
        cv::Mat processNoise= cv::Mat::zeros(2, 1, CV_32F);

        double ticks = 0;


        float calEnergy( const cv::Mat& eye, const cv::Point& eyeCenter, cv::Mat& outDebugImage );
    };
}

#endif /* PixelCount_hpp */
