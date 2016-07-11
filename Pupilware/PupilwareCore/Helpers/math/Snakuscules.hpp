//
// Created by Chatchai Wangwiwattana on 6/15/16.
//

#ifndef PUPILWARE_SNAKUSCULES_HPP
#define PUPILWARE_SNAKUSCULES_HPP

#include <opencv2/opencv.hpp>
#include "Circle.h"

namespace pw {

    struct RegionEnergy{
        RegionEnergy(unsigned int intensity, unsigned int numPixel)
                :intensity(intensity), numPixel(numPixel){}

        unsigned int intensity{0};
        unsigned int numPixel{0};
    };


    class Snakuscules {

    public:

        virtual void fit( const cv::Mat& srcGray
                , cv::Point seedPoint
                , int radius
                , const float alpha = 2.0
                , const unsigned int maxIteration = 20 ) = 0;

        virtual cv::Point getFitCenter() const = 0;
        virtual float getOuterRadius() const = 0;
        virtual float getInnerRadius() const = 0;

        virtual void calEnergyMat(const cv::Mat& srcGray
                                , cv::Mat& dst
                                , int radius
                                , const float alpha = 2.0) = 0;

        /*!
         * Static Methods
         */
        static std::shared_ptr<Snakuscules> Create();

    };

}

#endif //PUPILWARE_SNAKUSCULES_HPP
