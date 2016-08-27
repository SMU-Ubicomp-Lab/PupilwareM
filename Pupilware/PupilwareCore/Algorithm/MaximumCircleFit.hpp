//
//  MaximumCircleFit.hpp
//  Pupilware
//
//  Created by Chatchai Wangwiwattana on 5/25/16.
//  Copyright © 2016 Chatchai Wangwiwattana. All rights reserved.
//

#ifndef MAXIMUM_CIRCLE_FIT_HPP
#define MAXIMUM_CIRCLE_FIT_HPP

#include "IPupilAlgorithm.hpp"

namespace pw {

    class MaximumCircleFit : public IPupilAlgorithm {

    public:
        MaximumCircleFit( const std::string& name );
        MaximumCircleFit( const MaximumCircleFit& other)=default;
        MaximumCircleFit( MaximumCircleFit&& other)=default;
        MaximumCircleFit& operator=( const MaximumCircleFit& other)=default;
        MaximumCircleFit& operator=( MaximumCircleFit&& other)=default;
        virtual ~MaximumCircleFit();

        virtual void init() override ;

        virtual PWPupilSize process( const cv::Mat& src, const PWFaceMeta &meta ) override;

        virtual void exit() override ;
        
        const cv::Mat& getDebugImage() const;

        
        /* Setter and Getter */
        void setThreshold( float value );
        
    private:


        // It is used in dynamic thresholding
        float threshold;

        double ticks;

        cv::KalmanFilter KF;
        cv::Mat measurement = cv::Mat::zeros(1, 1, CV_32F);


        // Just a window name for debuging
        std::shared_ptr<CVWindow> window;
        
        // Debug Image
        cv::Mat debugImage;


        float findPupilSize(const cv::Mat &colorEyeFrame,
                            cv::Point eyeCenter,
                            cv::Mat &debugImg);

        float estimatePupilSize( float left, float right);

        float calCircularEnergy(const cv::Mat& src, const cv::Point& center, int radius);
    };
}

#endif /* MAXIMUM_CIRCLE_FIT_HPP */
