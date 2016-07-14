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
        Snakuscules();
        
        void fit( const cv::Mat& srcGray
                , cv::Point seedPoint
                , int radius
                , const float alpha = 2.0
                , const unsigned int maxIteration = 20 );

        cv::Point getFitCenter() const;
        float getOuterRadius() const;
        float getInnerRadius() const;

        void calEnergyMat(const cv::Mat& srcGray
                                , cv::Mat& dst
                                , int radius
                                , const float alpha = 2.0);
        
        
    private:
        cv::Point m_center;
        float m_outerRadius;
        float m_innerRadius;
        
        float _calInnerRadius( int radius, float alpha );
        RegionEnergy _calRegionEnergy(  const cv::Mat srcGray
                         , cv::Point center
                         , int radius              );
        
        double _calSnakeEnergy(   const cv::Mat srcGray
                        , const cv::Point center
                        , const int outerRadius
                               , const int innerRadius     );

    };

}

#endif //PUPILWARE_SNAKUSCULES_HPP
